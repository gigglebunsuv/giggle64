extends "res://scripts/enemies/stalfos.gd"
## A Barrow Knight (Chapter V): one of the old kings' sworn knights, risen in
## the Barrow of Kings with its tower shield still up. It fences like a
## Stalfos, but its shield turns every blow from in front, even while it
## attacks. What gets through: a SHIELD BASH (the knight reels, guard down,
## for GUARD_BREAK seconds), a blow from behind, a bomb, the Down Thrust's
## shock, or the Ember Rod's fire (the dead burn).
## The Barrow Champion and the Cinder Vault's Ember Knights are the same
## knight in other colors; a knight with a `title_name` is a mini-boss and
## names itself the first time it sees the hero.

const GUARD_BREAK := 2.4

@export var title_name := ""
@export var title_epithet := ""
@export var slash_damage := 2

var _broken := 0.0
var _named := false


func _ready() -> void:
	super._ready()
	if attack_hitbox:
		attack_hitbox.damage = slash_damage
		attack_hitbox.knockback = 6.0


func _physics_process(delta: float) -> void:
	_broken = maxf(_broken - delta, 0.0)
	if not _named and title_name != "" and state == State.APPROACH:
		_named = true
		Cutscene.boss_intro(self, title_name, title_epithet, World.MINIBOSS_TRACK, 1.9, 6.0, 2.2)
	super._physics_process(delta)


func guard_broken() -> bool:
	return _broken > 0.0


## The bash staggers it, shield wide: open to anything for a moment.
func _bashed(info: HitInfo) -> int:
	_broken = GUARD_BREAK
	var away := _flat_to(info.source_position) * -1.0
	away = away.normalized() if away.length() > 0.01 else -_forward()
	velocity.x = away.x * info.knockback
	velocity.z = away.z * info.knockback
	Sfx.play("shield_block", 0.0, 0.05, 0.7)
	Sfx.play("bone_rattle", -4.0, 0.05, 0.9)
	stun_left = GUARD_BREAK
	_go(State.STUNNED)
	return Hurtbox.Result.HIT


func _guard(info: HitInfo) -> int:
	if _broken > 0.0 or info.bomb or info.kind in ["ember", "thrust"] or state in [State.STUNNED, State.HURT, State.HOP_BACK]:
		return Hurtbox.Result.HIT
	if info.cleave:
		# A greatsword smashes the shield aside, and the blow lands.
		_bashed(info)
		return Hurtbox.Result.HIT
	var to := _flat_to(info.source_position)
	if to.length() > 0.01 and _forward().dot(to.normalized()) > cos(deg_to_rad(80.0)):
		Sfx.play("shield_block", -2.0, 0.05, 0.8)
		_guard_flash = 0.4
		if state in [State.IDLE, State.APPROACH, State.STRAFE]:
			model.play(&"guard", 0.02, 1.0, true)
			if _rng.randf() < 0.35 and _flat_dist(info.source_position) < 3.0:
				_go(State.WINDUP)
		return Hurtbox.Result.BLOCKED
	return Hurtbox.Result.HIT
