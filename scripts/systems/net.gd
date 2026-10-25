extends Node
## Online co-op (Beta 1.9.0): up to six players in one world over ENet, the
## host's. Everyone plays a hero: Sir Gigglebuns or one of the companions
## made playable (Pink, Aladriel, Idrith, Mira, Himeko), each with his whole
## arsenal.
##
## The host is the authority. Its world is the world:
## - Progress is shared. Whoever's items, coins, flags or gear change sends the
##   whole of it (Progress.to_dict) to everyone, and the last word stands. Only
##   the host's file is ever saved.
## - The party travels together: the host's area is everyone's. A client
##   stepping through an exit asks the host, who takes everyone (World.change_area).
## - The host runs the creatures. Clients show them as the host reports
##   (place, facing, animation, health, death) with their own thinking off; a
##   client's blow on one is sent to the host, who deals it.
## - Each player runs their own hero and reports it 20 times a second; the
##   others show a RemoteHero for it, which creatures on the host chase and
##   strike like the host's own hero (the blow is sent on to its player).
## - PvP (the host's choice): heroes' blows and arrows land on each other too.
## Started from the pause screen's OPTIONS > ONLINE, or from the command line:
##   -- --net-host[=port]  --net-join=address[:port]  --net-char=<id>  --net-name=<name>

signal roster_changed
signal status(text: String)

const PORT := 24064
const MAX_PLAYERS := 6
## Who can be played, in the order the CHARACTER option cycles them, and how
## tall each stands beside the hero (the companions' skeleton is 0.84 / 0.92
## of his, times each one's own scale).
const CHARACTERS := ["gigglebuns", "pink", "aladriel", "idrith", "mira", "himeko"]
const NAMES := {"gigglebuns": "SIR GIGGLEBUNS", "pink": "PINK", "aladriel": "ALADRIEL",
	"idrith": "IDRITH", "mira": "MIRA", "himeko": "HIMEKO"}
const HEIGHTS := {"gigglebuns": 1.0, "pink": 0.913, "aladriel": 0.968, "idrith": 0.886, "mira": 0.913, "himeko": 0.904}
const STATE_RATE := 20.0
const ENEMY_RATE := 15.0
## Progress changes are gathered this long before they go out.
const PROGRESS_DELAY := 0.3

var character := "gigglebuns"
var player_name := ""
var address := "127.0.0.1"
var pvp := false
var active := false
var is_host := false
## Everyone in the game: peer id -> {name, character, slot}.
var roster := {}
## The latest report from each other player: peer id -> state.
var states := {}
## The other heroes shown in this area: peer id -> RemoteHero.
var puppets := {}

var _peer: ENetMultiplayerPeer
var _state_t := 0.0
var _enemy_t := 0.0
var _progress_t := -1.0
var _applying := false
## A client's own area change, allowed through because the host asked for it.
var _forced := false
var _cli_done := false
## Creature targets from the host: node -> [position, yaw].
var _enemy_to := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)
	Progress.changed.connect(_on_progress_changed)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--net-char="):
			var c := a.trim_prefix("--net-char=")
			if c in CHARACTERS:
				character = c
		elif a.begins_with("--net-name="):
			player_name = a.trim_prefix("--net-name=")


func is_client() -> bool:
	return active and not is_host


func display_name() -> String:
	return player_name if player_name != "" else NAMES.get(character, "HERO")


static func model_path(id: String) -> String:
	if id == "gigglebuns" or not (id in CHARACTERS):
		return "res://assets/models/sir_gigglebuns.tscn"
	return "res://assets/models/playable_%s.tscn" % id


# --- Starting and stopping ------------------------------------------------------------

func host(port := PORT) -> bool:
	leave()
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_server(port, MAX_PLAYERS - 1) != OK:
		status.emit("COULD NOT HOST ON PORT %d" % port)
		_peer = null
		return false
	multiplayer.multiplayer_peer = _peer
	active = true
	is_host = true
	roster = {1: {"name": display_name(), "character": character, "slot": 0}}
	status.emit("HOSTING ON PORT %d" % port)
	roster_changed.emit()
	return true


func join(addr := "", port := PORT) -> bool:
	leave()
	if addr == "":
		addr = address
	if addr.contains(":"):
		port = int(addr.get_slice(":", 1))
		addr = addr.get_slice(":", 0)
	address = addr
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_client(addr, port) != OK:
		status.emit("COULD NOT REACH %s" % addr)
		_peer = null
		return false
	multiplayer.multiplayer_peer = _peer
	active = true
	is_host = false
	status.emit("JOINING %s..." % addr)
	return true


func leave() -> void:
	if _peer:
		_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = null
	var was := active
	active = false
	is_host = false
	roster.clear()
	states.clear()
	_clear_puppets()
	_wake_enemies()
	if was:
		status.emit("OFFLINE")
		roster_changed.emit()


func set_pvp(on: bool) -> void:
	if is_client():
		return
	pvp = on
	if active:
		_pvp.rpc(on)
	_apply_pvp()


func set_character(id: String) -> void:
	if not (id in CHARACTERS):
		return
	character = id
	var p := GameManager.player
	if is_instance_valid(p):
		p.swap_character(id)
	if active:
		_hello_again.rpc(display_name(), character)


# --- Connections ------------------------------------------------------------------

func _on_peer_connected(_id: int) -> void:
	pass


func _on_connected() -> void:
	_hello.rpc_id(1, display_name(), character)


func _on_failed() -> void:
	status.emit("COULD NOT CONNECT")
	leave()


func _on_server_gone() -> void:
	status.emit("THE HOST HAS LEFT")
	leave()


func _on_peer_disconnected(id: int) -> void:
	roster.erase(id)
	states.erase(id)
	if puppets.has(id):
		var p: Node = puppets[id]
		if is_instance_valid(p):
			p.queue_free()
		puppets.erase(id)
	if is_host:
		_roster.rpc(roster)
	roster_changed.emit()


@rpc("any_peer", "reliable")
func _hello(who: String, ch: String) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	var used := []
	for r in roster.values():
		used.append(r.slot)
	var slot := 1
	while slot in used:
		slot += 1
	roster[id] = {"name": who, "character": ch, "slot": slot}
	_welcome.rpc_id(id, roster, Progress.to_dict(), World.area_id, World.entrance_id, pvp)
	_roster.rpc(roster)
	roster_changed.emit()
	status.emit("%s JOINED" % who)


@rpc("any_peer", "reliable")
func _hello_again(who: String, ch: String) -> void:
	var id := multiplayer.get_remote_sender_id()
	if roster.has(id):
		roster[id].name = who
		roster[id].character = ch
	if puppets.has(id) and is_instance_valid(puppets[id]):
		(puppets[id] as Node).queue_free()
		puppets.erase(id)
	roster_changed.emit()


@rpc("authority", "reliable")
func _welcome(r: Dictionary, progress: Dictionary, area: String, entrance: String, pvp_on: bool) -> void:
	roster = r
	pvp = pvp_on
	_take_progress(progress)
	status.emit("JOINED THE GAME")
	roster_changed.emit()
	_forced = true
	World.change_area(area, entrance)
	_forced = false


@rpc("authority", "reliable")
func _roster(r: Dictionary) -> void:
	roster = r
	roster_changed.emit()


@rpc("authority", "reliable")
func _pvp(on: bool) -> void:
	pvp = on
	_apply_pvp()
	status.emit("PVP " + ("ON" if on else "OFF"))


func _apply_pvp() -> void:
	for p in puppets.values():
		if is_instance_valid(p):
			(p as RemoteHero).set_pvp(pvp)


## This player's place in the party (0 for the host), for spreading the
## party out where it arrives.
func slot() -> int:
	var me := multiplayer.get_unique_id() if active else 1
	return int(roster.get(me, {}).get("slot", 0))


# --- Areas --------------------------------------------------------------------------

## World.change_area asks first. True when it must not go ahead: a client
## asks the host to take everyone instead. The host tells everyone to follow.
func intercept_area_change(area: String, entrance: String) -> bool:
	if not active:
		return false
	if is_host:
		_goto.rpc(area, entrance)
		return false
	if _forced:
		return false
	_request_area.rpc_id(1, area, entrance)
	return true


@rpc("any_peer", "reliable")
func _request_area(area: String, entrance: String) -> void:
	if is_host and not World.transitioning:
		World.change_area(area, entrance)


@rpc("authority", "reliable")
func _goto(area: String, entrance: String) -> void:
	_forced = true
	World.change_area(area, entrance)
	_forced = false


# --- Shared progress ----------------------------------------------------------------

func _on_progress_changed() -> void:
	if active and not _applying and _progress_t < 0.0:
		_progress_t = PROGRESS_DELAY


@rpc("any_peer", "reliable")
func _progress(data: Dictionary) -> void:
	_take_progress(data)


func _take_progress(data: Dictionary) -> void:
	_applying = true
	var slot_was := Progress.slot
	Progress.from_dict(data)
	Progress.slot = slot_was
	Progress.gear_changed.emit()
	_applying = false


# --- Every frame ---------------------------------------------------------------------

func _process(delta: float) -> void:
	_command_line()
	if not active:
		return
	if _progress_t >= 0.0:
		_progress_t -= delta
		if _progress_t < 0.0:
			_progress.rpc(Progress.to_dict())
	_state_t += delta
	if _state_t >= 1.0 / STATE_RATE:
		_state_t = 0.0
		_send_state()
	if is_host:
		_enemy_t += delta
		if _enemy_t >= 1.0 / ENEMY_RATE:
			_enemy_t = 0.0
			_send_enemies()
	else:
		_follow_enemies(delta)
	_update_puppets()


func _command_line() -> void:
	if _cli_done or GameManager.state != GameManager.GameState.PLAYING or World.transitioning:
		return
	_cli_done = true
	for a in OS.get_cmdline_user_args():
		if a == "--net-host" or a.begins_with("--net-host="):
			host(int(a.get_slice("=", 1)) if a.contains("=") else PORT)
		elif a.begins_with("--net-join="):
			join(a.trim_prefix("--net-join="))
	if character != "gigglebuns" and is_instance_valid(GameManager.player):
		GameManager.player.swap_character(character)


# --- Heroes ----------------------------------------------------------------------------

func _send_state() -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or World.transitioning:
		return
	var m := p.model
	var st := {
		"a": World.area_id, "p": p.global_position + p.global_basis * m.position, "y": p.facing_yaw,
		"an": String(m.current_anim), "at": m.anim.current_animation_position if m.anim.is_playing() else 0.0,
		"as": m.anim.speed_scale, "sw": p.sword_drawn, "bo": m._bow_out, "nk": m.bow_nocked,
		"up": p._upper_name, "uw": m.upper_weight, "tr": p.trail != null and p.trail.emitting,
		"tc": p.trail != null and p.trail.color == SwordTrail.RED, "hp": p.health.health, "mh": p.health.max_health,
		"d": p.is_dead(), "v": m.visible or p.is_first_person(), "ch": character,
	}
	_state.rpc(st)


@rpc("any_peer", "unreliable_ordered")
func _state(st: Dictionary) -> void:
	var id := multiplayer.get_remote_sender_id()
	states[id] = st
	if puppets.has(id) and is_instance_valid(puppets[id]):
		(puppets[id] as RemoteHero).apply_state(st)


func _update_puppets() -> void:
	var area := World.area_node
	for id in states.keys():
		var st: Dictionary = states[id]
		var here := is_instance_valid(area) and not World.transitioning and String(st.get("a", "")) == World.area_id
		var p: RemoteHero = puppets.get(id) if puppets.has(id) and is_instance_valid(puppets[id]) else null
		if p and (not here or p.get_parent() != area or p.net_character != String(st.get("ch", "gigglebuns"))):
			p.queue_free()
			puppets.erase(id)
			p = null
		if here and p == null:
			p = RemoteHero.make(id, String(st.get("ch", "gigglebuns")), String(roster.get(id, {}).get("name", "PLAYER")))
			area.add_child(p)
			p.global_position = st.get("p", Vector3.ZERO)
			p.set_pvp(pvp)
			puppets[id] = p
			p.apply_state(st)
	for id in puppets.keys():
		if not states.has(id):
			if is_instance_valid(puppets[id]):
				(puppets[id] as Node).queue_free()
			puppets.erase(id)


func _clear_puppets() -> void:
	for p in puppets.values():
		if is_instance_valid(p):
			(p as Node).queue_free()
	puppets.clear()


## Every hero in this area: this player's own first, then the others shown here.
func heroes() -> Array:
	var out: Array = []
	if is_instance_valid(GameManager.player):
		out.append(GameManager.player)
	if active:
		for p in puppets.values():
			if is_instance_valid(p) and (p as Node).is_inside_tree():
				out.append(p)
	return out


func _puppet_of(id: int) -> RemoteHero:
	var p: Variant = puppets.get(id)
	return p if p != null and is_instance_valid(p) else null


# --- Blows between heroes and creatures ---------------------------------------------------

## A RemoteHero was struck here: a creature's blow (on the host) or, with
## PvP, this player's own. It goes on to that hero's player.
func hit_remote_hero(target: RemoteHero, info: HitInfo) -> int:
	if not active:
		return Hurtbox.Result.IGNORED
	var from_hero := info.attacker == GameManager.player
	if from_hero and not pvp:
		return Hurtbox.Result.IGNORED
	var path := ""
	if info.attacker is Enemy and is_instance_valid(World.area_node):
		path = str(World.area_node.get_path_to(info.attacker))
	_debug("hero %d struck for %d (pvp %s)" % [target.peer_id, info.damage, from_hero])
	_hero_hit.rpc_id(target.peer_id, info.damage, info.knockback, info.unblockable, info.source_position, info.kind, path, from_hero)
	target.model.flash(Color(1.0, 0.4, 0.4), 0.08)
	return Hurtbox.Result.HIT


@rpc("any_peer", "reliable")
func _hero_hit(damage: int, knockback: float, unblockable: bool, source: Vector3, kind: String, attacker_path: String, pvp_hit: bool) -> void:
	var p := GameManager.player
	if not is_instance_valid(p) or (pvp_hit and not pvp):
		return
	var info := HitInfo.new()
	info.damage = damage
	info.knockback = knockback
	info.unblockable = unblockable
	info.source_position = source
	info.kind = "" if pvp_hit else kind
	var by: Node3D = null
	if attacker_path != "" and is_instance_valid(World.area_node):
		by = World.area_node.get_node_or_null(attacker_path) as Node3D
	if by == null:
		by = _puppet_of(multiplayer.get_remote_sender_id())
	info.attacker = by
	p.take_hit(info)


## Hurtbox.receive_hit asks first: on a client, a blow on a creature goes to
## the host (who runs it), and here it only flashes. True when sent on.
func forward_hit(receiver: Node, info: HitInfo) -> bool:
	if not is_client() or not (receiver is Enemy) or not is_instance_valid(World.area_node):
		return false
	var e := receiver as Enemy
	if e.is_dead():
		return true
	var flags := (1 if info.heavy else 0) | (2 if info.bomb else 0) | (4 if info.cleave else 0) | (8 if info.reflected else 0) | (16 if info.unblockable else 0)
	_enemy_hit.rpc_id(1, World.area_id, str(World.area_node.get_path_to(e)), info.damage, info.knockback, info.kind, flags, info.source_position)
	if e.model:
		e.model.flash(Color(1.0, 0.95, 0.8), 0.08)
	Sfx.play("enemy_hurt", -4.0)
	return true


@rpc("any_peer", "reliable")
func _enemy_hit(area: String, path: String, damage: int, knockback: float, kind: String, flags: int, source: Vector3) -> void:
	if not is_host or area != World.area_id or not is_instance_valid(World.area_node):
		return
	var e := World.area_node.get_node_or_null(path) as Enemy
	if e == null or e.is_dead():
		return
	var info := HitInfo.new()
	info.damage = damage
	info.knockback = knockback
	info.kind = kind
	info.heavy = flags & 1 != 0
	info.bomb = flags & 2 != 0
	info.cleave = flags & 4 != 0
	info.reflected = flags & 8 != 0
	info.unblockable = flags & 16 != 0
	info.source_position = source
	var by := _puppet_of(multiplayer.get_remote_sender_id())
	info.attacker = by if by else GameManager.player
	_debug("enemy hit from %d on %s for %d" % [multiplayer.get_remote_sender_id(), path, damage])
	if e.hurtbox:
		e.hurtbox.receive_hit(info)
	else:
		e.take_hit(info)


func _debug(text: String) -> void:
	if OS.get_environment("G64_NET_DEBUG") != "":
		print("NET ", text)


## A client's parry turned a creature's blow: it reels on the host too.
func parried_by_me(attacker: Node) -> void:
	if is_client() and attacker is Enemy and is_instance_valid(World.area_node):
		_enemy_parried.rpc_id(1, World.area_id, str(World.area_node.get_path_to(attacker)))


@rpc("any_peer", "reliable")
func _enemy_parried(area: String, path: String) -> void:
	if not is_host or area != World.area_id or not is_instance_valid(World.area_node):
		return
	var e := World.area_node.get_node_or_null(path) as Enemy
	var by := _puppet_of(multiplayer.get_remote_sender_id())
	if e and by and e.has_method("parried"):
		e.parried(by)


# --- Creatures ----------------------------------------------------------------------------

func _send_enemies() -> void:
	var area := World.area_node
	if not is_instance_valid(area) or World.transitioning:
		return
	var list: Array = []
	for n in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e == null or not area.is_ancestor_of(e):
			continue
		list.append([str(area.get_path_to(e)), e.global_position, e.rotation.y,
			String(e.model.current_anim) if e.model else "", e.health.health if e.health else 0, e.is_dead(), e.visible,
			e.scene_file_path])
	_enemies.rpc(World.area_id, list)


@rpc("authority", "unreliable_ordered")
func _enemies(area: String, list: Array) -> void:
	if area != World.area_id or not is_instance_valid(World.area_node) or World.transitioning:
		return
	var seen := {}
	for row: Array in list:
		var path := String(row[0])
		seen[path] = true
		var e := World.area_node.get_node_or_null(path) as Enemy
		if e == null and _copies.has(path) and is_instance_valid(_copies[path]):
			e = _copies[path]
		if e == null:
			e = _copy_enemy(path, String(row[7]) if row.size() > 7 else "", row[1])
		if e == null:
			continue
		_quiet(e)
		_enemy_to[e] = [row[1], float(row[2])]
		var anim := StringName(row[3])
		if e.model and anim != &"" and e.model.current_anim != anim:
			e.model.play(anim, 0.1)
		e.visible = bool(row[6])
		if e.health and not e.is_dead():
			if bool(row[5]):
				e.health.apply_damage(e.health.health)
			else:
				e.health.health = int(row[4])


	# Copies of creatures the host has since lost (dead and gone) go too.
	for path in _copies.keys():
		if not seen.has(path):
			if is_instance_valid(_copies[path]):
				(_copies[path] as Node).queue_free()
			_copies.erase(path)


## Creatures the host made as it went (spawners, waves) that this world never
## had: made here from the same scene, under the same parent where there is
## one (path -> Enemy).
var _copies := {}


func _copy_enemy(path: String, scene: String, at: Vector3) -> Enemy:
	if scene == "" or not ResourceLoader.exists(scene):
		return null
	var e := (load(scene) as PackedScene).instantiate() as Enemy
	if e == null:
		return null
	var slash := path.rfind("/")
	var parent: Node = World.area_node
	if slash > 0:
		parent = World.area_node.get_node_or_null(path.substr(0, slash))
		if parent == null:
			parent = World.area_node
	var leaf := path.substr(slash + 1)
	if leaf.validate_node_name() == leaf:
		e.name = leaf
	e.set_physics_process(false)
	parent.add_child(e)
	e.global_position = at
	_copies[path] = e
	return e


## A creature on a client does no thinking of its own: the host's does.
func _quiet(e: Enemy) -> void:
	if e.is_physics_processing():
		e.set_physics_process(false)
		if e.attack_hitbox:
			e.attack_hitbox.deactivate()


func _follow_enemies(delta: float) -> void:
	var gone: Array = []
	for e: Variant in _enemy_to:
		if not is_instance_valid(e):
			gone.append(e)
			continue
		var en := e as Enemy
		var to: Array = _enemy_to[e]
		en.global_position = en.global_position.lerp(to[0], 1.0 - exp(-14.0 * delta))
		en.rotation.y = lerp_angle(en.rotation.y, float(to[1]), 1.0 - exp(-14.0 * delta))
	for e in gone:
		_enemy_to.erase(e)
	# New arrivals think nothing either, before the host's first word on them.
	if is_instance_valid(World.area_node):
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Enemy and World.area_node.is_ancestor_of(n):
				_quiet(n as Enemy)


func _wake_enemies() -> void:
	_enemy_to.clear()
	for e in _copies.values():
		if is_instance_valid(e):
			(e as Node).queue_free()
	_copies.clear()
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Enemy and not (n as Enemy).is_dead():
			(n as Node).set_physics_process(true)
