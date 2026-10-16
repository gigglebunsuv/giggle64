class_name ShopItem
extends Node3D
## Something for sale on a shop counter, after OoT's shops (EnGirlA): facing
## it, A says CHECK and the box gives its name, price and what it does, then
## asks "Buy / Don't buy". Buying takes the rupees and hands the goods over
## (with the get-item fanfare for anything lasting). It can't be bought
## without the rupees, or when it would do nothing (a full quiver...).
##
## The kinds (`kind`):
##   arrows_10    ten arrows (needs the bow, not with a full quiver)
##   heart        one heart of health now (not at full health)
##   honey_bun    three hearts of health now (Idrith's recipe)
##   big_quiver   the quiver holds 40 arrows (once)
##   bomb_bag     a bag of 20 bombs (once)
##   bombs_10     ten bombs (needs the bag, not with a full one)
##   bottle       an empty bottle (once)
##   red_potion   a red potion, poured into an empty bottle
##   puff_nuts    ten Puff Nuts (the first buy brings the pouch, which holds 20)

@export var kind := "arrows_10"
@export var price := 10
## The mesh shown on the counter (assets/models/<mesh>.tres).
@export var mesh := ""
## Only on sale once this flag is set ("" = always): a market stall in the
## rebuilt town waits for its district (Beta 1.5.0).
@export var show_flag := ""

const INFO := {
	"arrows_10": {"name": "Arrows (10)", "text": "Ten arrows for your quiver."},
	"heart": {"name": "Recovery Heart", "text": "Restores one heart of life energy, right away."},
	"honey_bun": {"name": "Honey Bun", "text": "One of Idrith's honey buns! Restores three hearts. Eat it right here."},
	"big_quiver": {"name": "Big Quiver", "text": "A roomy quiver. It holds *40* arrows!"},
	"bomb_bag": {"name": "Bomb Bag", "text": "A bag of *20 Bombs*! They blow cracked walls wide open. Handle with care!"},
	"bombs_10": {"name": "Bombs (10)", "text": "Ten bombs for your bag."},
	"bottle": {"name": "Empty Bottle", "text": "A sturdy glass bottle. Catch a *fairy* in it, or carry a potion!"},
	"red_potion": {"name": "Red Potion", "text": "Fills every one of your hearts. You'll need an *empty bottle* to carry it."},
	"puff_nuts": {"name": "Puff Nuts (10)", "text": "Throw one and it bursts in a flash of spores that leaves every foe nearby *dazed*. Comes with a pouch!"},
}

var _mesh: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	if show_flag != "" and not Progress.flag(show_flag):
		queue_free()
		return
	add_to_group("interactable")
	add_to_group("shop_items")
	if mesh != "" and ResourceLoader.exists("res://assets/models/%s.tres" % mesh):
		_mesh = MeshInstance3D.new()
		_mesh.name = "Goods"
		_mesh.mesh = load("res://assets/models/%s.tres" % mesh)
		add_child(_mesh)
	_refresh()
	Progress.changed.connect(_refresh)


func _process(delta: float) -> void:
	_t += delta
	if _mesh:
		_mesh.rotation.y = _t * 0.8


## A one-off item disappears from the counter once bought.
func _refresh() -> void:
	visible = not sold_out()


func sold_out() -> bool:
	match kind:
		"big_quiver":
			return Progress.arrows_max >= 40
		"bomb_bag":
			return Progress.has_item("bombs")
		"bottle":
			return Progress.flag("shop_bottle")
	return false


func can_interact(_by: Node3D) -> bool:
	return not sold_out()


func interact_label() -> String:
	return "CHECK"


func item_name() -> String:
	return INFO.get(kind, {}).get("name", kind)


func interact(player: Node) -> void:
	if Dialogue.active:
		return
	var info: Dictionary = INFO.get(kind, {"name": kind, "text": ""})
	var pages: Array = [
		{"text": "*%s*: %d Coins\n%s" % [info.name, price, info.text], "choices": [["Buy", []], ["Don't buy", []]]},
	]
	if player is PlayerController:
		(player as PlayerController).begin_talk(self)
	Dialogue.start(pages, self)
	await Dialogue.finished
	if Dialogue.last_choice == "Buy" and player is PlayerController and is_instance_valid(player):
		await _buy(player as PlayerController)
	if player is PlayerController and is_instance_valid(player):
		(player as PlayerController).end_talk()


## Why the goods can't be had right now ("" = they can).
func refusal(player: PlayerController) -> String:
	match kind:
		"arrows_10":
			if not Progress.has_item("bow"):
				return "You don't have a bow to shoot them with!"
			if Progress.arrows >= Progress.arrows_max:
				return "Your quiver is already full!"
		"heart", "honey_bun":
			if player.health.health >= player.health.max_health:
				return "You're already in perfect health!"
		"red_potion":
			if not "empty" in Progress.bottles:
				return "You'll need an *empty bottle* to carry it!"
		"bombs_10":
			if not Progress.has_item("bombs"):
				return "You need a *Bomb Bag* to carry them!"
			if Progress.bombs >= Progress.bombs_max:
				return "Your bomb bag is already full!"
		"puff_nuts":
			if Progress.nuts_max > 0 and Progress.nuts >= Progress.nuts_max:
				return "Your nut pouch is already full!"
	if Progress.rupees < price:
		return "You don't have enough Coins!"
	return ""


func _buy(player: PlayerController) -> void:
	var no := refusal(player)
	if no != "":
		Sfx.play("error", -4.0)
		Dialogue.start([no], self)
		await Dialogue.finished
		return
	Progress.add_rupees(-price)
	match kind:
		"arrows_10":
			Progress.add_arrows(10)
			Sfx.play("item_pop", -4.0)
			Dialogue.start(["Thank you!\nYou got *10 Arrows*."], self)
			await Dialogue.finished
		"heart":
			player.health.heal(2)
			Sfx.play("heart", -4.0)
		"honey_bun":
			player.health.heal(6)
			Sfx.play("heart", -4.0)
			Dialogue.start(["Mmm! Sweet, sticky and still warm. You feel much better!"], self)
			await Dialogue.finished
		"big_quiver", "bomb_bag":
			player.end_talk()
			await GetItem.present(player, kind)
		"bottle":
			Progress.set_flag("shop_bottle")
			player.end_talk()
			await GetItem.present(player, "bottle")
		"red_potion":
			Progress.set_bottle(Progress.bottles.find("empty"), "red_potion")
			Sfx.play("bottle_pour", -4.0)
			Dialogue.start(["Thank you!\nYou poured a *Red Potion* into your bottle."], self)
			await Dialogue.finished
		"bombs_10":
			Progress.add_bombs(10)
			Sfx.play("item_pop", -4.0)
			Dialogue.start(["Thank you!\nYou got *10 Bombs*."], self)
			await Dialogue.finished
		"puff_nuts":
			if Progress.has_item("puff_nuts"):
				Progress.add_nuts(10)
				Sfx.play("item_pop", -4.0)
				Dialogue.start(["Thank you!\nYou got *10 Puff Nuts*."], self)
				await Dialogue.finished
			else:
				player.end_talk()
				await GetItem.present(player, "puff_nuts")
