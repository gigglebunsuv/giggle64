class_name PlayerController
extends CharacterBody3D
## Movement and state machine for Sir Gigglebuns IV.
##
## Ground and air movement reproduce Link's movement in Ocarina of Time, worked
## out from the zeldaret/oot decompilation (z_player.c, z_player_lib.c, z_lib.c).
## Nothing is copied; the behavior and tuning numbers are re-expressed here:
##
## - OoT runs its game logic at 20 Hz and moves actors by velocity * 1.5 per frame
##   (R_UPDATE_RATE 3 * 0.5). Speeds, steps and gravity below are kept in OoT units
##   per OoT frame and converted with `oot_unit` meters per unit (adult Link is
##   about 62 units tall; the hero is 1.85 m).
## - The stick is read as a 0-60 magnitude. Free movement uses OoT's "curved"
##   speed mode: nothing below 20, then target = ((1 - cos(m * 450)) ^ 2 * 30 + 7) * 0.14,
##   capped at the run limit of 6 (R_RUN_SPEED_LIMIT 600). Lock-on and the air use
##   the linear mode (magnitude * 0.8 * 0.14).
## - Standing still, a pushed stick snaps the facing to the stick at once and
##   starts running. A slightly pushed stick (no speed yet) turns in place.
## - Running, speed steps toward the target by +2.0 / -1.5 per frame and the
##   movement direction turns by at most 2000 binary angle units per frame
##   (scaled x1.5, about 330 deg/s); the body follows it at the same rate.
## - Pushing more than 135 deg (0x6000) away from the run direction stops dead
##   (R_DECELERATE_RATE 8) and the next frame starts running the other way.
## - A is the action button. It first interacts with anything in the "interactable"
##   group in reach. Otherwise (Player_ActionHandler_Roll / _10) it rolls when the
##   stick is pushed (past 55 of 60), side-hops (vy 3.5, speed 8.5) or back-flips
##   (vy 5.8, speed 6) when Z-targeting with the stick left/right/back, and with the
##   stick neutral puts the sword away. A never jumps on its own. Running off a
##   ledge still jumps automatically (vy 7.5 above speed 5.9, otherwise
##   1.25 + 0.2 * speed).
## - Jump slash (Player_ActionHandler_10 -> func_8083BA90): Z-targeting with the
##   stick neutral or forward and the sword in hand (or locked on to an enemy,
##   which draws it), A leaps forward (speed 5, vy 5) with the sword raised.
##   B in mid-air does the same from any jump or side hop but the back flip
##   (func_8083BBA0: speed 3, vy 4.5). The leap falls under hop gravity (1.2),
##   steers like a jump (func_8083DFE0) and the blade is live from frame 6
##   (func_8084285C); landing (func_80843E64) brings the sword down in the
##   finishing chop (PLAYER_MWA_JUMPSLASH_FINISH). Jump attacks hit for double
##   (DMG_JUMP_* against DMG_SLASH_*).
## - "Put Away" (Player_UpdateInterface): the sword stays drawn after attacking;
##   A offers to sheathe it once nothing else would use A for 20 frames (1 s).
## - Shield (Player_ActionHandler_11): without Z-targeting the hero crouches behind
##   it with his feet planted (Player_Action_80843188, the "defense" pose); while
##   Z-targeting it is raised on the upper body only, so he can still strafe
##   (func_80834758 / func_80834B5C).
## - Airborne, there is almost no steering: speed changes by +0.05 / -0.1 per frame
##   and direction by 200 units per frame. Gravity is 1.0 per frame (1.2 during hops).
## - A roll faster than 7 into a wall bonks the hero back.
##
## Z-targeting follows Player_UpdateZTargeting:
## - Z with a target in range locks on. In Switch mode the lock stays until Z is
##   pressed again (which moves to another target or lets go); in Hold mode it
##   ends when Z is released.
## - Z with nothing to target starts "parallel" mode (Player_SetParallel) for as
##   long as Z is held: the body keeps facing `parallel_yaw`, the camera swings
##   behind it and the stick strafes (func_8083FD78):
##   * within 6000 units (33 deg) of the facing: walk forward (Player_Action_8084227C)
##   * straight back (speed > cos(angle / 2) * 200): back-walk at 1.5x the stick
##     speed (Player_Action_808414F8)
##   * anything else: side-step along the stick at 0.9x the stick speed, or 0.4x
##     below a stick speed of 4.9 (Player_Action_8084193C / Player_Action_80840DE4)
##
## Ledges, after the wall check in Player_UpdateBgcCheck and Player_ActionHandler_12:
## - Pushing into a near-vertical wall, a probe drops from 111 units above the
##   feet (adult unk_0C) just past the wall. A flat top 18-111 units up is a
##   ledge (none if a ceiling or more wall is in the way). Below 41 (unk_1C) the
##   hero hops up (vy = height * 0.08 + 5.5, speed 2.5) after 3 frames of
##   pushing; up to 59 (unk_18) and 79.4 (unk_14) he pulls himself up with the
##   short and tall step-up after 6 frames; higher than that he jumps
##   (vy = height * 0.072, Player_Action_80845668) and grabs the edge.
##   Surfaces flagged "climb_with_a" (OoT's WALL_FLAG_6 blocks) wait for A ("CLIMB").
## - In the air, touching a wall whose ledge is in reach and at least 70 units
##   above the floor below, he catches it and hangs (jump_climb_hold).
## - Walking off an edge slower than the automatic jump (speed 3) with more than
##   70 units below, he turns and hangs from it (func_8083A6AC).
## - Hanging (Player_Action_8084BBE4): pushing the stick climbs up
##   (jump_climb_up); A lets go.
## Ladders (WALL_FLAG_1, func_8083EC18 / Player_Action_8084BF1C): walking into one
## grabs it, snapped to its 15-unit rungs. Up and down climb one rung per step at
## an animation rate of |stick| * 0.05 (1 to 3.35); the top is climbed over when a
## floor appears 70 units up, the bottom stepped off within 15 units of the
## ground, and A lets go. Walking slowly off a ledge onto a ladder grabs it too.
##
## First-person view (RB, OoT's C-Up, Player_Action_8084B1D8 / func_8084ABD8):
## the hero stands still; the stick turns him 16 units per frame per stick unit
## (3000 at most) and sets the pitch directly (stick_y * 240, eased 1/14 per
## frame). The mouse turns and tilts the view too. A, B, R or RB returns.
## The bow (an item button): the view switches to first person (CAM_MODE_AIM_ADULT,
## letterboxed) and the stick aims with OoT's curve ((1 - cos(stick * 200)) * 1500
## per frame, pitch within 14000). The arrow is ready after the bow_ready
## animation; releasing the button (or the mouse button) shoots, pressing again
## nocks the next (func_808351D4 / func_808353D8). While Z-targeting the bow is
## used without leaving the third-person view and shoots at the target.
##
## Lifting and throwing (Player_ActionHandler_2, PLAYER_STATE1_CARRYING_ACTOR):
## pots, small rocks and shrubs offer themselves to A ("GRAB") when the hero is
## within their range and faces them within 0x2000 (getItemDirection starts at
## 0x6000; the most squarely faced one wins). The lift (func_8083A0F4 with the
## carryB animation) puts the sword away, takes hold of the object on frame 4
## and raises it overhead; he then walks and runs with it as usual
## (Player_UpperAction_CarryActor only moves the upper body). A, B or an item
## button throws it (Player_ActionHandler_9; these are all ACTOR_FLAG_THROW_ONLY,
## so never put down): on frame 3 of the throw it leaves with his speed + 8 and
## 12 up (func_8084409C); from frame 8 the stick ends the throw early
## (Player_Action_80846578). Carrying, he does not climb ledges higher than a hop,
## ladders or hang from edges. A blow makes him drop it.
##
## Swimming (func_8083D53C, func_8084B000, func_8084AEEC and the swim actions
## Player_Action_8084D610 / _8084D84C / _8084DC48 / _8084E1EC), adult values:
## - Deeper than 56 units (depthInWater, unk_2C) he swims; shallower than 36
##   (unk_24) he wades out on his feet again.
## - He floats with his feet 44.8 units (unk_28) under the surface: above that
##   the water lets him sink by 0.1 a frame (more when rising), below it pushes
##   him up by 0.1 (more when sinking), to at most 2 a frame.
## - The stroke drives him: speed only builds during frames 10-20 of each stroke
##   (by up to 6 a frame toward 0.8 x the stick's linear speed, capped at 4.8) and
##   bleeds away by |speed| * 0.02 + 0.05 a frame; he turns 1600 units a frame.
## - A dives (gPlayerAnim_link_swimer_swim_deep_start): from frame 20 he sinks
##   at 2 a frame while A is held, down to 120 units (no scale); letting go he
##   rises at depth * 0.018 + 4 (at most 8) and surfaces above 68 (unk_30).
## - He can't use the sword or items in the water. Pushing against a low bank
##   pulls him up out of it.
##
## The Hookshot (Player_Action_HookshotFly, ArmsHook): its button aims in first
## person like the bow; letting go fires the chain (Hookshot). When it bites
## into a wooden target he is pulled along the chain to it, then drops from
## the target, catching the ledge above if there is one.
##
## Riding (Player_Action_8084B530 and friends): A beside Biscuit mounts her;
## she takes the stick (Horse). A spurs her on, or with her standing still,
## gets off on her left side. B swings the sword out to the side from the
## saddle. The bow on an item button aims from horseback in first person while
## she keeps running (OoT's horseback archery). Getting a treasure or talking
## takes him out of the saddle.
##
## The boomerang (func_80834EB8, func_808358F0, func_808359FC): holding its
## button readies it; without Z-targeting the camera goes to CAM_MODE_AIM_BOOMERANG
## (Camera_Subj3, 50 units behind his head) and the stick aims as with the bow.
## Releasing the button throws it along the aim, pitch included (EnBoom takes
## focus.rot.x), on frame 6 of the throw. While Z-targeting it is readied and
## thrown on the upper body, at the target, without leaving the third-person view.

## A blow was turned by the Parry (PlayerCombat.TECH_PARRY).
signal parried
signal state_changed(new_state: int)
signal respawned
signal arrow_fired(arrow: Node3D)

enum State { IDLE, MOVE, TURN, AIR, LAND, ROLL, BONK, ATTACK, BLOCK, SHEATHE, HURT, DEAD,
	CLIMB, HANG, LADDER, LOOK, AIM, TALK, LIFT, THROW, JUMPSLASH, SWIM, RIDE, HOOKFLY, ITEM, SLIDE }
## What a CLIMB state is doing.
enum Climb { HOP_JUMP, STEP_LOW, STEP_HIGH, JUMP_GRAB, HANG_UP, LADDER_TOP, LADDER_BOTTOM }
## Bow phases (OoT's upper-body bow actions).
enum Bow { NONE, READY, DRAWN, SHOT }
## Z-target movement actions while in State.MOVE with a parallel Z-target.
enum ZMove { NONE, FORWARD, SIDE, SIDE_SLOW, BACK }

## Adult swimming depths (sAgeProperties unk_24, unk_28, unk_2C, unk_30) and
## the deepest dive without a scale (D_80854784[0]), in OoT units.
const SWIM_EXIT := 36.0
const SWIM_FLOAT := 44.8
const SWIM_ENTER := 56.0
const SWIM_SURFACE := 68.0
const DIVE_MAX := 120.0
## The swim stroke: 22 animation frames; speed builds on frames 10-20.
const STROKE_FRAMES := 22.0

## OoT game logic rate and per-frame velocity scale.
const OOT_FPS := 20.0
const OOT_RATE := 1.5
## One OoT binary angle unit (0x10000 per turn) in radians.
const BINANG := TAU / 65536.0
## OoT stick directions relative to the facing (Player_ProcessControlStick).
enum StickDir { NONE = -1, FORWARD = 0, LEFT = 1, BACK = 2, RIGHT = 3 }
## Raised-shield arm pose layered over the legs while Z-targeting (same as the
## "block" animation's arm).
const Z_SHIELD_POSE := {
	"Hips/Torso/ShoulderL": Vector3(58, -32, 0),
	"Hips/Torso/ShoulderL/ElbowL": Vector3(118, 0, 0),
	"Hips/Torso/ShoulderL/ElbowL/Shield": Vector3(0, 62, 0),
}
## Bow held out at arm's length with the string drawn to the cheek, layered
## over the legs like the shield (OoT plays the bow on the upper skeleton).
const BOW_POSE := {
	"Hips/Torso": Vector3(0, -8, 0),
	"Hips/Torso/Head": Vector3(-4, 8, 0),
	"Hips/Torso/ShoulderL": Vector3(92, 0, -4),
	"Hips/Torso/ShoulderL/ElbowL": Vector3(4, 0, 0),
	"Hips/Torso/ShoulderR": Vector3(86, 0, 14),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(138, 0, 0),
}

## Shield aim per unit of stick (0-60) and its limits, in OoT binary angles.
const SHIELD_AIM_YAW := 120.0
const SHIELD_AIM_PITCH := 100.0
const SHIELD_AIM_PITCH_DOWN := 3500.0

## Throwing the boomerang: the right arm flung out, on the upper body only.
const THROW_POSE := {
	"Hips/Torso": Vector3(0, -25, 0),
	"Hips/Torso/ShoulderR": Vector3(80, 0, 20),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(10, 0, 0),
}
const THROW_TIME := 0.35
## boom_throw_waitR: the boomerang held back by the right shoulder, ready.
const BOOM_READY_POSE := {
	"Hips/Torso": Vector3(0, 20, 0),
	"Hips/Torso/ShoulderR": Vector3(95, 0, 55),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(95, 0, 0),
	"Hips/Torso/ShoulderR/ElbowR/HandR": Vector3(-30, 0, 0),
}
## carryB_wait: both hands up over his head, elbows out, holding the object
## on his palms.
const CARRY_POSE := {
	"Hips/Torso": Vector3(4, 0, 0),
	"Hips/Torso/Head": Vector3(-6, 0, 0),
	"Hips/Torso/ShoulderR": Vector3(165, 0, 16),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(30, 0, 0),
	"Hips/Torso/ShoulderR/ElbowR/HandR": Vector3(-40, 0, 0),
	"Hips/Torso/ShoulderL": Vector3(165, 0, -16),
	"Hips/Torso/ShoulderL/ElbowL": Vector3(30, 0, 0),
}
## Holding the fishing rod out over the water, tip up.
const FISH_POSE := {
	"Hips/Torso": Vector3(-4, 0, 0),
	"Hips/Torso/ShoulderR": Vector3(50, 0, 8),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(24, 0, 0),
	"Hips/Torso/ShoulderR/ElbowR/HandR": Vector3(-10, 0, 0),
	"Hips/Torso/ShoulderL": Vector3(40, -30, 0),
	"Hips/Torso/ShoulderL/ElbowL": Vector3(60, 0, 0),
}
## Gathering strength for the Great Spin: the blade drawn back low at his
## right side, the body wound up to the right.
const CHARGE_POSE := {
	"Hips/Torso": Vector3(-10, 30, 0),
	"Hips/Torso/Head": Vector3(6, -28, 0),
	"Hips/Torso/ShoulderR": Vector3(20, 60, 30),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(30, 0, 0),
	"Hips/Torso/ShoulderR/ElbowR/HandR": Vector3(-60, 90, 0),
}
## The Shield Bash: the shield arm shoved straight out.
const BASH_POSE := {
	"Hips/Torso": Vector3(-14, 10, 0),
	"Hips/Torso/ShoulderL": Vector3(88, 10, -6),
	"Hips/Torso/ShoulderL/ElbowL": Vector3(30, 0, 0),
	"Hips/Torso/ShoulderL/ElbowL/Shield": Vector3(0, 62, 0),
}
## A two-handed sword (the Questlord's Greatsword): R holds the blade across
## the body, edge out, in place of the shield (the left hand finds the grip by
## itself, CharacterModel.two_hand).
const BLADE_GUARD_POSE := {
	"Hips/Torso": Vector3(-6, 0, 0),
	"Hips/Torso/ShoulderR": Vector3(62, 38, 0),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(96, 0, 0),
	"Hips/Torso/ShoulderR/ElbowR/HandR": Vector3(-20, 0, -78),
}
## ...and held ready in both hands, low in front with the point raised.
const GREAT_READY_POSE := {
	"Hips/Torso": Vector3(0, -22, 0),
	"Hips/Torso/Head": Vector3(0, 20, 0),
	"Hips/Torso/ShoulderR": Vector3(34, 26, 0),
	"Hips/Torso/ShoulderR/ElbowR": Vector3(62, 0, 0),
	"Hips/Torso/ShoulderR/ElbowR/HandR": Vector3(-44, 0, 0),
}
## The joints a cut plays on over the rest of the body (CharacterModel.play_upper):
## the sword arm alone for the stab behind the crouched shield, and the chest
## with it for the slash from the saddle (the legs stay on the horse).
const ARM_R_PATHS := ["Hips/Torso/ShoulderR", "Hips/Torso/ShoulderR/ElbowR", "Hips/Torso/ShoulderR/ElbowR/HandR"]
const RIDE_SLASH_PATHS := ["Hips/Torso", "Hips/Torso/Head", "Hips/Torso/ShoulderR", "Hips/Torso/ShoulderR/ElbowR",
	"Hips/Torso/ShoulderR/ElbowR/HandR"]
## Upper-body layers by name (see _update_upper_pose).
const UPPER_POSES := {
	"shield": Z_SHIELD_POSE, "bow": BOW_POSE, "throw": THROW_POSE,
	"boom_ready": BOOM_READY_POSE, "carry": CARRY_POSE, "fish": FISH_POSE,
	"charge": CHARGE_POSE, "bash": BASH_POSE,
	"guard": BLADE_GUARD_POSE, "great_ready": GREAT_READY_POSE,
}

## Adult Link's ledge and climbing measurements in OoT units (sAgeProperties).
const LEDGE_PROBE := 111.0
const LEDGE_MIN := 18.0
const LEDGE_HOP := 41.0
const LEDGE_STEP := 59.0
const LEDGE_PULL := 79.4
const HANG_CLEARANCE := 70.0
const RUNG := 15.0
## OoT's flat-floor test for a ledge top (|normal.y| > 0x6D60).
const LEDGE_FLAT := 0.856
## A ledge's top must reach this far to either side of the hero (meters).
const PERCH_HALF_WIDTH := 0.25
## A wall is a surface within this of vertical (OoT: |normal.y| < 600 / 32767,
## loosened a little for float collision normals).
const WALL_MAX_NY := 0.1
## Facing within 0x3000 of the wall counts as pushing into it.
const WALL_FACE := 0x3000
## Falls, in OoT units from where he last stood (fallDistance): past 80 the
## stick held forward rolls out of the landing; from 400 the landing hurts
## (half a heart), from 800 more (a heart) and rolling no longer saves him
## (Player_Action_8084411C's landing, func_80843E64, D_80854600).
const FALL_ROLL := 80.0
const FALL_HURT := 400.0
const FALL_HURT_BIG := 800.0
## The landing_damage crouch, and OoT's 40 frames of intangibility after it.
const LAND_HARD_TIME := 0.9
const LAND_HARD_INVULN := 2.0
## Player_CanSpinAttack: four stick samples (20 Hz), each at least 5 of 128
## steps round from the last (10 in its doubled units), all the same way.
const QUICKSPIN_STEP := 5
## Items that are aimed (State.AIM / the Z-target upper body). Pressing one of
## these while another is out swaps it in place (Player_UpperAction_ChangeHeldItem).
const AIM_ITEMS: Array[String] = ["bow", "sun_arrows", "frost_arrows", "starfall_arrows", "hookshot", "boomerang", "bloom_rod"]
## Cycles that put a foot down at their start and halfway through (footsteps).
const STEP_ANIMS: Array[StringName] = [&"walk", &"run", &"run_sword", &"sidestep", &"turn"]

@export var camera_rig: AdventureCamera

@export_group("Scale")
## Meters per OoT world unit.
@export var oot_unit := 0.03

@export_group("Ground Movement (OoT units)")
@export var run_speed_limit := 6.0
@export var run_accel := 2.0
@export var run_decel := 1.5
@export var stop_decel := 8.0
@export var run_turn_step := 2000.0
@export var turn_in_place_step := 1200.0
## Stick angle away from the run direction that triggers a stop-and-reverse.
@export var reverse_angle := 0x6000
@export_range(30.0, 60.0) var max_slope_deg := 48.0
## Keyboard walk key scales the stick to this magnitude (0-1).
@export var walk_stick := 0.7

@export_group("Air & Hops (OoT units)")
@export var gravity_oot := 1.0
@export var hop_gravity_oot := 1.2
@export var max_fall_oot := 20.0
@export var air_accel := 0.05
@export var air_decel := 0.1
@export var air_turn_step := 200.0
@export var sidehop_velocity_oot := 3.5
@export var sidehop_speed := 8.5
@export var backflip_velocity_oot := 5.8
@export var backflip_speed := 6.0
## Drop needed below the feet before running off an edge counts as a ledge jump.
@export var ledge_jump_min_drop := 0.6
@export var hard_landing_speed := 9.5
@export var land_time := 0.16

@export_group("Roll")
## OoT: 20 animation frames at 1.25x speed, advanced 1.5 frames per game frame.
@export var roll_time := 0.533
@export var roll_bonk_speed := 7.0
@export var roll_invuln_start := 0.21
@export var roll_invuln_time := 0.5

@export_group("Jump Slash (OoT units)")
## func_8083BA90 from Z + A, and from B in mid-air (func_8083BBA0).
@export var jumpslash_speed := 5.0
@export var jumpslash_vy := 5.0
@export var air_jumpslash_speed := 3.0
@export var air_jumpslash_vy := 4.5
## Lpower_jump_kiru's frame 6 (30 animation frames a second).
@export var jumpslash_hit_start := 0.2
## Lpower_jump_kiru_hit: the chop is live for its first frames, and the hero
## rises from the crouch by the end of _end.
@export var jumpslash_land_hit := 0.12
@export var jumpslash_land_time := 0.5

@export_group("Sword")
## putAwayCooldownTimer: 20 OoT frames before A offers "Put Away".
@export var put_away_delay := 1.0
@export var sheathe_time := 0.5

@export_group("Carrying")
## carryB: the object is taken in hand on frame 4 (the animation advances 1.5
## frames per 20 Hz frame) and is overhead when the lift ends.
@export var lift_time := 0.5
@export var lift_grab_time := 0.13
## throw: released on frame 3 and over after 0.45 s, or from frame 8 if the
## stick is pushed.
@export var carry_throw_time := 0.45
@export var carry_throw_release := 0.1
@export var carry_throw_early := 0.27
## func_8084409C: forward speed added to the hero's own, and upward velocity
## (OoT units per frame).
@export var carry_throw_speed := 8.0
@export var carry_throw_vy := 12.0
## OoT's getItemDirection window: the object must lie within this of the facing.
@export var lift_face_angle := 0x2000

@export_group("Damage & Recovery")
@export var hurt_time := 0.4
@export var invulnerability_time := 1.1
@export var kill_height := -12.0
@export var fall_damage := 2
@export var respawn_delay := 2.6

@export_group("Targeting")
@export var target_range := 11.0
@export var target_face_step := 4000.0

@export_group("Interaction")
## How far in front of the hero A reaches for an interactable.
@export var interact_range := 1.6
## How far below / above the hero's feet an interactable may stand (meters).
const INTERACT_BELOW := -1.3
const INTERACT_ABOVE := 2.4

@export_group("Climbing")
## Feet below the ledge while hanging from it (hands at the edge).
@export var hang_reach := 1.95
## Seconds for the step-up animations (100step_up / 150step_up / jump_climb_up
## at OoT's 1.3x playback) and the jump-and-grab wind-up (8 frames).
@export var step_low_time := 0.55
@export var step_high_time := 0.8
@export var hang_up_time := 1.0
@export var jump_grab_windup := 0.2
## The hang settles before the stick or A can act (the grab animation's first frames).
@export var hang_settle := 0.25

@export_group("Look & Bow")
## Eye height for the first-person view.
@export var eye_height := 1.68
## bow_ready / bow_shoot_next before an arrow can fly.
@export var bow_ready_time := 0.3
## boom_throw_wait2waitR: readying the boomerang before a release throws it,
## and boom_throwR's frame 6, when it leaves the hand.
@export var boomerang_ready_time := 0.25
@export var boomerang_release_time := 0.2
## CAM_MODE_AIM_BOOMERANG and CAM_MODE_AIM_ADULT (the bow) put the eye 50
## units (1.5 m) behind the head.
@export var boomerang_aim_distance := 1.5
@export var bow_aim_distance := 1.5
## How far the reticle looks for a target for the bow (an arrow's 12 frames
## at 150 units carry it about 80 m).
@export var aim_reach_bow := 80.0
## While aiming, draw only the arms and what they hold, as OoT does when the
## camera is behind the head (Player_OverrideLimbDrawGameplayFirstPerson).
@export var aim_arms_only := true

@onready var health: HealthComponent = $Health
@onready var combat: PlayerCombat = $Combat
@onready var model: CharacterModel = $Model
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var target_marker: Node3D = $TargetMarker

var state: State = State.IDLE
## Body facing (OoT shape.rot.y), in Godot yaw radians: 0 faces -Z.
var facing_yaw := 0.0
## Movement direction (OoT this->yaw).
var move_yaw := 0.0
var lock_target: Enemy = null
## Z held with nothing locked on (OoT PLAYER_STATE1_PARALLEL).
var parallel := false
## Facing frozen when parallel mode started (OoT parallelYaw).
var parallel_yaw := 0.0
var z_move := ZMove.NONE
## Sword in hand (true) or on the back. It starts sheathed, as in OoT.
var sword_drawn := false
var input_enabled := true
## Optional override for automated tests: a world-space move vector used instead of keys.
var debug_move_input := Vector3.ZERO
var debug_use_move_input := false
## Scripted walk used by area transitions (OoT walks Link into an exit and out
## of the entrance). Player input is ignored while it runs.
var _auto_walk_time := 0.0
var _auto_walk_dir := Vector3.ZERO
## Ground speed in OoT units per frame (OoT speedXZ).
var speed_oot := 0.0

## Hero top speed in m/s (derived from the OoT run limit).
var run_speed: float:
	get: return _to_mps(run_speed_limit)

var _state_time := 0.0
var _invuln_time := 0.0
var _air_time := 0.0
var _pre_move_vy := 0.0
var _hop := false
var _jumped := false
var _hop_dir := StickDir.NONE
var _z_shield := false
## Player_Action_80843188: the crouched shield aimed with the stick, in
## radians: x = yaw over the hips (left +), y = pitch (forward/down +).
var shield_aim := Vector2.ZERO
var _put_away_cooldown := 0.0
## The current lock-on was made in Switch mode (OoT PLAYER_STATE2_LOCK_ON_WITH_SWITCH).
var _lock_switch := false
var _spawn_transform: Transform3D
var _blink_time := 0.0
var _lean := Vector2.ZERO
var _stick_mag := 0.0
var _stick_yaw := 0.0
## The real stick (x right, y up, 0-60), or INF when the move comes from a
## script (tests, auto-walks) as a world direction.
var _stick_raw := Vector2.INF

## Ledge bookkeeping (OoT ledgeClimbType / ledgeClimbDelayTimer, in 20 Hz frames).
var _ledge_type := 0
var _ledge_timer := 0.0
var _ledge := {}
## The wall touched this frame: {n (flat, out of the wall), point, shape}.
var _wall := {}
var _last_floor_y := 0.0
var _no_grab_time := 0.0
var _climb_kind := Climb.STEP_LOW
var _climb_time := 1.0
## Model offset (in the hero's local space) eased back to zero during climbs,
## so the picture moves smoothly while the body jumps to its new place.
var _offset_from := Vector3.ZERO
var _offset_time := 0.0
## Quicksand (scripts/dungeon/quicksand.gd): how deep the hero has sunk (the
## model drops by it), and seconds left before he counts as out of the sand.
var sink := 0.0
var in_sand := 0.0
## Wind (scripts/dungeon/wind_zone.gd) pushing on the hero this frame, in m/s;
## the Wind Boots let him stand firm against it.
var wind_push := Vector3.ZERO
var _wind_now := Vector3.ZERO
## Holding A in the air with the Wind Boots on: a slow glide, for a while.
const GLIDE_FALL := 1.3
const GLIDE_TIME := 1.6
## Without the Wind Boots, a gale catches the hero in the air: it pushes this
## much harder than on the ground, and holds his fall to this (m/s).
const WIND_CARRY := 1.7
const WIND_CARRY_FALL := 1.6
var gliding := false
var _glide_left := GLIDE_TIME
## On ice the hero keeps sliding: his ground velocity only slowly follows
## what he is trying to do (ICE_GRIP of the way per 60th of a second).
const ICE_GRIP := 0.045
var on_ice := false
var _slide := Vector3.ZERO
var _offset_dur := 0.0
var _offset_two_phase := false
## Ladder: {n, center, bottom, top}; step direction, from/to heights and timing.
var _ladder := {}
var _ladder_dir := 0
var _ladder_from := 0.0
var _ladder_to := 0.0
var _ladder_t := 0.0
var _ladder_len := 0.0

## First-person view direction: yaw (Godot convention) and pitch (up +).
var look_yaw := 0.0
var look_pitch := 0.0
var _look_by_mouse := false
## Tests: a stick vector (x right, y up, -1..1) used instead of the real sticks.
var debug_look_input := Vector2.ZERO
## Tests: holds the bow string as if the item button were held.
var debug_bow_hold := false
var bow_phase := Bow.NONE
var _bow_time := 0.0
var _aim_button := ""
## Using the bow from the third-person view while Z-targeting.
var bow_z := false
## The Hookshot readied on the upper body while Z-targeting: it fires at the
## target (or straight ahead in parallel mode) without leaving the view.
var hook_z := false
## OoT fallStartHeight: the height he last stood (or hung, swam, rode) at.
var _fall_start_y := 0.0
var _last_pos := Vector3.ZERO
## How long the current LAND lasts (a hard landing holds longer).
var _land_hold := 0.16
## Player_ProcessControlStick's controlStickSpinAngles: the stick's angle in
## 128ths of a turn, sampled at OoT's 20 Hz (-1 when not pushed past 55).
var _spin_angles: Array[int] = [-1, -1, -1, -1]
var _spin_sample := 0.0
## OoT pushedSpeed / pushedYaw: a slippery slope holding him back as he climbs it.
var _push_speed := 0.0
var _push_yaw := 0.0
## Sliding (Player_Action_SlideOnSlope) facing up the slope.
var _slide_up := false
var talk_partner: Node3D = null
## Footsteps: the cycle phase last frame (-1 = not stepping), which foot is
## next, and the surface of the last step (see Surface).
var _step_phase := -1.0
var _foot := 0
var last_surface := ""
## Footstep loudness (dB on the Footsteps bus): a creep, a full run, and the
## random spread of each step.
const STEP_QUIET_DB := -22.0
const STEP_LOUD_DB := -9.0
const STEP_SPREAD := 2.5
## A bottled fairy is bringing the hero back from this fall.
var _fairy_revive := false
## Seconds the hero's boots stay wet after swimming (squelching steps).
const WET_TIME := 8.0
var wet_time := 0.0
## Holding up a treasure (GetItem): TALK with the get-item pose.
var item_get := false
## In a cutscene (Cutscene): halted, unhurt, posed by `cs_anim`.
var in_cutscene := false
var cs_anim: StringName = &""
## The boomerang in flight (only one at a time), and the throw pose timer.
var boomerang: Node3D = null
var _throw_time := 0.0
## The aim lies on something the shot can hit (see _update_aim_target).
var aim_on_target := false
## What State.AIM is aiming: "bow" or "boomerang".
var aim_item := ""
## The arrow the bow fires now: "" (plain), "sun" or "frost" (PlayerItems.ARROW_KINDS).
var arrow_kind := ""
## The newer items (Puff Nuts, the Iron Mallet, the Lantern, the Looking
## Glass, the Fishing Rod and the goddesses' blessings); State.ITEM is theirs.
var items: PlayerItems
## Boomerang readied: -1 = no; otherwise seconds since it was readied.
var _boom_ready := -1.0
## Seconds since the throwing swing started (-1 = not throwing).
var _boom_throw := -1.0
## The boomerang is readied on the upper body while Z-targeting.
var boom_z := false
## What is carried overhead (PLAYER_STATE1_CARRYING_ACTOR), and the lift in progress.
var held: Throwable = null
var _lift_thing: Node3D = null
var _lift_from := Transform3D.IDENTITY
var _thrown := false
var _upper_name := ""
## The jump slash has come down (the finishing chop is playing).
var _js_landed := false
## The Down Thrust (Knight's Techniques): a JUMPSLASH straight down.
var _thrust := false
## The Great Spin turns the body a full circle from this yaw.
var _spin_from := 0.0
## How far he must be above the ground for B in the air to be a Down Thrust.
const THRUST_MIN_DROP := 1.4
const THRUST_FALL := 15.0
const THRUST_RECOVER := 0.45
## Holding Mira's fishing rod (FishingSpot).
var fishing := false
## How deep the hero's feet are under the water, in OoT units (depthInWater;
## -1 out of water).
var water_depth := -1.0
var _water_y := NAN
## The swim stroke's animation frame, and the dive (0 none, 1 going down,
## 2 coming up).
var _stroke := 0.0
var diving := 0
## The horse he's riding (State.RIDE), aiming the bow from her back, and the
## sword swing from the saddle (seconds left).
var horse: Horse = null
var riding_aim := false
## The Hookshot's chain while it is out, and the launcher in his hand.
var hook: Hookshot = null
var _hook_mesh: MeshInstance3D = null
var _ride_swing := 0.0
var _rod: MeshInstance3D = null


func _ready() -> void:
	# Heart containers raise the maximum for the whole game.
	health.max_health = Progress.max_health
	health.health = health.max_health
	floor_max_angle = deg_to_rad(max_slope_deg)
	floor_snap_length = 0.3
	_spawn_transform = global_transform
	facing_yaw = rotation.y
	move_yaw = facing_yaw
	health.died.connect(_on_died)
	combat.setup(self)
	items = PlayerItems.new()
	items.name = "Items"
	add_child(items)
	items.setup(self)
	_apply_gear()
	Progress.gear_changed.connect(_apply_gear)
	_set_upper("shield")
	model.set_sword_drawn(false)
	target_marker.top_level = true
	target_marker.visible = false
	add_to_group("player")
	GameManager.register_player(self)
	# Settle onto the ground on the first physics tick (even while the title pauses the game).
	get_tree().physics_frame.connect(_snap_to_ground, CONNECT_ONE_SHOT)


## Shows the equipped sword and shield and takes on their strength.
func _apply_gear() -> void:
	model.set_gear(Equipment.sword_look(Progress.sword), Progress.shield)
	model.set_gilded(Progress.flag("shield_polish"))
	model.set_starlight(Progress.sword == "bun" and Progress.sword_awake())
	model.set_boots(Progress.boot)
	model.set_outfit(Progress.tunic, Progress.vanity_on)
	combat.apply_gear()


func _snap_to_ground() -> void:
	var from := global_position + Vector3.UP * 2.0
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 30.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position.y = hit.position.y
	_spawn_transform = global_transform
	if camera_rig:
		camera_rig.snap_behind_target()


func is_dead() -> bool:
	return state == State.DEAD


func forward() -> Vector3:
	return _dir(facing_yaw)


## Wind Boots: holding A while falling holds the fall to a slow glide.
func _update_glide(delta: float) -> void:
	if is_on_floor():
		_glide_left = GLIDE_TIME
		gliding = false
		return
	var want := state == State.AIR and not _hop and velocity.y < 0.0 and Progress.wind_boots() \
		and input_enabled and Input.is_action_pressed("interact") and _glide_left > 0.0 and not is_carrying()
	if want and not gliding:
		Sfx.play("throw", -6.0, 0.05, 0.6)
	gliding = want
	if gliding:
		_glide_left -= delta
		velocity.y = maxf(velocity.y, -GLIDE_FALL)


## Ice underfoot: the hero's ground velocity lags behind what he wants.
func _update_ice(delta: float) -> void:
	var flat := Vector3(velocity.x, 0, velocity.z)
	on_ice = is_on_floor() and state in [State.IDLE, State.MOVE, State.TURN, State.LAND, State.ATTACK, State.BLOCK] \
		and Surface.under(get_world_3d(), global_position, World.area_node, 0.4) == "ice"
	if on_ice:
		var k := 1.0 - pow(1.0 - ICE_GRIP, delta * 60.0)
		flat = _slide.lerp(flat, k)
		velocity.x = flat.x
		velocity.z = flat.z
	_slide = flat


## The wind's push. The Wind Boots hold him fast against it on his feet;
## gliding on them, the wind fills his cloak and carries him further.
func _update_wind() -> void:
	_wind_now = wind_push
	wind_push = Vector3.ZERO
	if _wind_now == Vector3.ZERO or state in [State.DEAD, State.TALK]:
		return
	var k := 1.0
	if Progress.wind_boots():
		k = 1.5 if gliding else 0.0
	elif Progress.anchor_boots():
		k = 0.0
	elif state == State.AIR and not is_on_floor():
		# Barefoot of the Wind Boots and off his feet, he is light enough for
		# a gale to take him: leap into it and it carries him on, his cloak
		# full of it, holding his fall while he rides with the wind.
		k = WIND_CARRY
		var along := Vector2(velocity.x, velocity.z).dot(Vector2(_wind_now.x, _wind_now.z).normalized())
		if along > -0.5:
			velocity.y = maxf(velocity.y, -WIND_CARRY_FALL)
	velocity.x += _wind_now.x * k
	velocity.z += _wind_now.z * k


## The wind he stood in last frame (for tests and the camera).
func wind_now() -> Vector3:
	return _wind_now


## Where the shield faces: the facing turned by the crouched aim.
func shield_forward() -> Vector3:
	return _dir(facing_yaw + shield_aim.x) if state == State.BLOCK else forward()


## Where light thrown off the raised Mirror Shield leaves it (SunShaft).
func shield_point() -> Vector3:
	return global_position + Vector3.UP * 1.1 + shield_forward() * 0.45


## And which way it goes: along the shield, tilted by the crouched aim.
func shield_beam_dir() -> Vector3:
	var pitch := shield_aim.y if state == State.BLOCK else 0.0
	return (shield_forward() * cos(pitch) + Vector3.DOWN * sin(pitch)).normalized()


## True while standing still with no input, which drives the camera's idle realign.
func is_idle_for_camera() -> bool:
	return state == State.IDLE and is_on_floor() and _stick_mag < 1.0 \
		and Vector2(velocity.x, velocity.z).length() < 0.2


func is_invulnerable() -> bool:
	return _invuln_time > 0.0 or in_cutscene


## Shield up, either crouched (State.BLOCK) or raised while Z-targeting.
func is_shielding() -> bool:
	return state == State.BLOCK or _z_shield


## Player_IsZTargeting: locked on, or holding Z in parallel mode.
func is_z_targeting() -> bool:
	return lock_target != null or parallel


## The camera looks where the hero looks (C-Up view or aiming an item). It is
## in his head, or `aim_camera_back()` behind it.
func is_first_person() -> bool:
	return state == State.LOOK or state == State.AIM or riding_aim


## How far behind the head the aiming camera sits (Camera_Subj3's eyeNextDist).
func aim_camera_back() -> float:
	if state != State.AIM and not riding_aim:
		return 0.0
	return boomerang_aim_distance if aim_item == "boomerang" else bow_aim_distance


## Camera_Subj3's eyeNextYOffset: +5% of his height for the boomerang, -7% for
## the bow (sSetNormal0ModeAimBoomerangData / AimAdultData), from eye level.
func aim_camera_height() -> float:
	return (0.05 if aim_item == "boomerang" else -0.07) * 1.85


## Where an aimed shot or throw starts: the head, on the camera's line of sight,
## so it flies to the middle of the view.
func aim_origin() -> Vector3:
	return global_position + Vector3.UP * (eye_height + aim_camera_height())


func is_aiming() -> bool:
	return state == State.AIM or bow_z or hook_z or boom_z


## Something lifted is in his hands (PLAYER_STATE1_CARRYING_ACTOR).
func is_carrying() -> bool:
	return is_instance_valid(held) or state == State.LIFT


## Hanging from a ledge, on a ladder, or pulling himself up.
func is_climbing() -> bool:
	return state in [State.CLIMB, State.HANG, State.LADDER]


func eye_position() -> Vector3:
	return global_position + Vector3.UP * eye_height + forward() * 0.12


## Where the hero appears to be (the model may lag behind the body during a climb).
func focus_position() -> Vector3:
	return global_position + global_basis * model.position


## Turns the hero to face `dir` at once (doors, scripted moments).
func face_direction(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() < 0.01:
		return
	facing_yaw = _yaw_of(dir)
	move_yaw = facing_yaw
	rotation.y = facing_yaw


# --- OoT unit helpers ---------------------------------------------------------

## OoT units per frame -> meters per second.
func _to_mps(units: float) -> float:
	return units * OOT_RATE * OOT_FPS * oot_unit


## Number of OoT frames that `delta` covers.
func _frames(delta: float) -> float:
	return delta * OOT_FPS


## Math_ScaledStepToS: steps an angle by `binang_step` (x1.5) per OoT frame.
func _step_angle(from: float, to: float, binang_step: float, delta: float) -> float:
	var max_step := binang_step * OOT_RATE * BINANG * _frames(delta)
	return from + clampf(angle_difference(from, to), -max_step, max_step)


## Math_AsymStepToF over `delta`.
func _asym_step(from: float, to: float, incr: float, decr: float, delta: float) -> float:
	var step := (incr if to >= from else decr) * _frames(delta)
	return move_toward(from, to, step)


func _dir(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _yaw_of(v: Vector3) -> float:
	return atan2(-v.x, -v.z)


# --- Frame update -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_state_time += delta
	_invuln_time = maxf(_invuln_time - delta, 0.0)
	_no_grab_time = maxf(_no_grab_time - delta, 0.0)
	if _auto_walk_time > 0.0:
		_auto_walk_time -= delta
		if _auto_walk_time <= 0.0:
			input_enabled = true
	_read_stick()
	_sample_spin(delta)
	# Set down somewhere new (a warp, a void-out, a test): falls count from here.
	if global_position.distance_to(_last_pos) > 1.5:
		_fall_start_y = global_position.y
	_update_water()
	_update_chill(delta)
	_update_anchor(delta)
	_update_targeting()
	combat.physics_update(delta)
	items.physics_update(delta)
	_check_slope(delta)

	match state:
		State.HOOKFLY:
			_state_hookfly(delta)
		State.RIDE:
			_state_ride(delta)
		State.SWIM:
			_state_swim(delta)
		State.CLIMB:
			_state_climb(delta)
		State.HANG:
			_state_hang(delta)
		State.LADDER:
			_state_ladder(delta)
		State.LOOK:
			_state_look(delta)
		State.AIM:
			_state_aim(delta)
		State.TALK:
			_state_talk(delta)
		State.LIFT:
			_state_lift(delta)
		State.THROW:
			_state_throw(delta)
		State.JUMPSLASH:
			_state_jumpslash(delta)
		State.ITEM:
			items.state_update(delta)
		State.SLIDE:
			_state_slide(delta)
		State.IDLE, State.TURN:
			_state_idle(delta)
		State.MOVE:
			_state_move(delta)
		State.AIR:
			_state_air(delta)
		State.LAND:
			speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
			if _state_time >= _land_hold:
				_change_state(State.IDLE)
		State.ROLL:
			_state_roll(delta)
		State.BONK:
			speed_oot = move_toward(speed_oot, 0.0, 2.0 * _frames(delta))
			if _state_time >= 0.5:
				_change_state(State.IDLE)
		State.SHEATHE:
			speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
			if sword_drawn and _state_time >= sheathe_time * 0.5:
				_set_sword_drawn(false)
			if _state_time >= sheathe_time:
				_change_state(State.IDLE)
		State.ATTACK:
			_state_attack(delta)
		State.BLOCK:
			_state_block(delta)
		State.HURT:
			_decelerate_velocity(delta, 17.0)
			if _state_time >= hurt_time:
				_change_state(State.IDLE if is_on_floor() else State.AIR)
		State.DEAD:
			speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
			if _fairy_revive and _state_time >= 1.1:
				_revive_by_fairy()
			elif _state_time >= respawn_delay:
				# Game over (GameOver): the choice to continue, or the old
				# straight-back-up for the tests.
				if GameOver.auto_respawn or in_cutscene:
					respawn()
				elif not GameOver.showing():
					GameOver.open()

	# Player_UpdateShapeYaw: the body faces the lock-on target, the parallel yaw,
	# or (when walking forward or not Z-targeting) the movement direction.
	if state in [State.MOVE, State.AIR, State.LAND] and not _hop:
		if lock_target:
			_face_toward(lock_target.global_position, target_face_step, delta)
		elif parallel and not (state == State.MOVE and z_move == ZMove.FORWARD):
			facing_yaw = _step_angle(facing_yaw, parallel_yaw, target_face_step, delta)
		else:
			facing_yaw = _step_angle(facing_yaw, move_yaw, run_turn_step, delta)

	if is_climbing() or state == State.RIDE or state == State.HOOKFLY:
		# Hanging, on a ladder, climbing, riding or flying on the chain: the
		# body is placed directly.
		velocity = Vector3.ZERO
		_wall = {}
		_ledge_type = 0
		_ledge_timer = 0.0
	else:
		if state != State.HURT:
			var v := _dir(move_yaw) * _to_mps(speed_oot) * anchor_slow() * (0.45 if combat.charging else 1.0)
			# A slippery slope holds him back as he climbs it (pushedSpeed).
			v += _dir(_push_yaw) * _to_mps(_push_speed)
			velocity.x = v.x
			velocity.z = v.z
			if state == State.SLIDE and is_on_floor():
				# Keep to the slope instead of flying off it.
				var n := get_floor_normal()
				if n.y > 0.05:
					velocity.y = minf(0.0, -(v.x * n.x + v.z * n.z) / n.y)
		if not is_on_floor() and state != State.SWIM:
			var g := hop_gravity_oot if _hop or state == State.JUMPSLASH else gravity_oot
			velocity.y = maxf(velocity.y - _to_mps(g) * OOT_FPS * delta, -_to_mps(max_fall_oot))
		_update_glide(delta)
		_update_ice(delta)
		_update_wind()
		_pre_move_vy = velocity.y
		var was_on_floor := is_on_floor()
		move_and_slide()
		if is_on_floor():
			_last_floor_y = global_position.y
		_wall = _touched_wall()
		_update_air_transitions(was_on_floor)
		_update_ledges(delta)
	# fallStartHeight: wherever he stands, hangs, swims, rides or glides.
	if is_on_floor() or is_climbing() or gliding or state in [State.SWIM, State.RIDE, State.HOOKFLY]:
		_fall_start_y = global_position.y
	_last_pos = global_position
	rotation.y = facing_yaw
	_update_held()
	_update_model_offset(delta)
	_update_lean(delta)
	_update_shield_and_sword(delta)
	_update_blink(delta)
	_update_marker(delta)
	if state == State.SWIM:
		wet_time = WET_TIME
	else:
		wet_time = maxf(wet_time - delta, 0.0)
	_update_footsteps()
	if global_position.y < _kill_height():
		_fell_out()


## Below this he has fallen out of the world: `kill_height`, or further down
## in a dungeon whose lowest storey is deeper (the castle's dungeons at -16).
func _kill_height() -> float:
	var f := World.floors()
	return minf(kill_height, float(f[0][1]) - 10.0) if not f.is_empty() else kill_height


# --- Input --------------------------------------------------------------------

## Reads the stick as OoT does: a 0-60 magnitude and a world-space yaw.
func _read_stick() -> void:
	var world := Vector3.ZERO
	_stick_raw = Vector2.INF
	if debug_use_move_input:
		world = debug_move_input.limit_length(1.0)
	elif _auto_walk_time > 0.0 and state != State.DEAD:
		world = _auto_walk_dir
	elif input_enabled and state != State.DEAD:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Input.is_action_pressed("walk"):
			v = v.limit_length(walk_stick)
		# EnHorse_StickDirection reads the raw stick, not the camera's view of it.
		_stick_raw = Vector2(v.x, -v.y).limit_length(1.0) * 60.0
		if v != Vector2.ZERO:
			var fwd := camera_rig.forward_vector() if camera_rig else Vector3.FORWARD
			var right := camera_rig.right_vector() if camera_rig else Vector3.RIGHT
			world = (right * v.x + fwd * -v.y).limit_length(1.0)
	_stick_mag = world.length() * 60.0
	if _stick_mag > 0.0:
		_stick_yaw = _yaw_of(world)


## Player_CalcSpeedAndYawFromControlStick. Returns the target speed in OoT units.
func _stick_speed(curved: bool) -> float:
	if _stick_mag <= 0.0:
		return 0.0
	var s := _stick_mag
	if curved:
		s -= 20.0
		if s < 0.0:
			return 0.0
		var t := 1.0 - cos(s * 450.0 * BINANG)
		s = t * t * 30.0 + 7.0
	else:
		s *= 0.8
	s *= 0.14
	# Running uphill slows the hero (floor pitch influence, capped at sin 0.6).
	if is_on_floor():
		var uphill := clampf(-get_floor_normal().dot(_dir(_stick_yaw)), 0.0, 0.6)
		s -= 8.0 * uphill * uphill
	# Wading through quicksand is half speed.
	if in_sand > 0.0:
		s *= 0.5
	return clampf(s, 0.0, run_speed_limit)


## Stick direction relative to the facing; NONE unless pushed past 55 of 60.
func _stick_dir() -> StickDir:
	if _stick_mag < 55.0:
		return StickDir.NONE
	var rel := angle_difference(facing_yaw, _stick_yaw)
	if absf(rel) <= PI / 4.0:
		return StickDir.FORWARD
	if absf(rel) >= PI * 0.75:
		return StickDir.BACK
	return StickDir.LEFT if rel > 0.0 else StickDir.RIGHT


## func_8083FD78 for parallel mode: 1 walks forward, -1 back-walks, 0 side-steps.
func _parallel_class(target_speed: float) -> int:
	var rel := absf(angle_difference(parallel_yaw, _stick_yaw)) / BINANG
	if target_speed != 0.0 and rel < 6000.0:
		return 1
	if target_speed > cos(rel * 0.5 * BINANG) * 200.0:
		return -1
	return 0


## Target yaw for Z movement; with the stick neutral OoT uses the parallel yaw
## (Player_GetMovementSpeedAndYaw).
func _z_yaw_target() -> float:
	return _stick_yaw if _stick_mag > 0.0 else parallel_yaw


## The nearest interactable in front of the hero within reach, or null.
func interact_candidate() -> Node3D:
	var best: Node3D = null
	var best_dist := interact_range
	for n in get_tree().get_nodes_in_group("interactable"):
		var node := n as Node3D
		if node == null or not node.has_method("interact"):
			continue
		if node.has_method("can_interact") and not node.can_interact(self):
			continue
		var to := node.global_position - global_position
		# OoT's talk / door checks also want the thing at about the hero's own
		# height (yDistToPlayer): never a door or a chest a floor above or below.
		var dy := to.y
		if dy < INTERACT_BELOW or dy > INTERACT_ABOVE:
			continue
		to.y = 0.0
		var dist := to.length()
		var reach: float = node.interact_reach() if node.has_method("interact_reach") else interact_range
		if dist <= reach and (best == null or dist < best_dist) and (dist < 0.3 or to.normalized().dot(forward()) > 0.5) \
				and _can_see_interactable(node):
			best = node
			best_dist = dist
	return best


## No wall between the hero and the thing: a level line at head height (over
## counters, tables and chests) to above it meets nothing but the thing
## itself (or the wall it hangs on, right at it).
func _can_see_interactable(node: Node3D) -> bool:
	var from := global_position + Vector3.UP * 1.5
	var at := Vector3(node.global_position.x, from.y, node.global_position.z)
	var q := PhysicsRayQueryParameters3D.create(from, at, 1)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return true
	var c: Object = hit.collider
	if c == node or (c is Node and (node.is_ancestor_of(c) or (c as Node).is_ancestor_of(node))):
		return true
	var near := Vector2(hit.position.x - node.global_position.x, hit.position.z - node.global_position.z)
	return near.length() < 0.35


# --- States -------------------------------------------------------------------

## Player_Action_Idle and Player_Action_TurnInPlace.
func _state_idle(delta: float) -> void:
	speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
	if not is_on_floor() and _air_time > 0.1:
		_change_state(State.AIR)
		return
	if _try_actions():
		return
	if lock_target:
		_face_toward(lock_target.global_position, target_face_step, delta)
		if _stick_speed(false) > 0.0:
			_start_moving(_stick_yaw, false)
			return
		model.play(&"idle", 0.15)
		return
	if parallel:
		_idle_parallel(delta)
		return
	var target := _stick_speed(true)
	if target > 0.0:
		_start_moving(_stick_yaw, true)
		return
	if _stick_mag > 0.0 and absf(angle_difference(facing_yaw, _stick_yaw)) > 800.0 * BINANG:
		if state != State.TURN:
			_change_state(State.TURN)
		facing_yaw = _step_angle(facing_yaw, _stick_yaw, turn_in_place_step, delta)
		move_yaw = facing_yaw
		model.play(&"turn", 0.08)
		return
	if state == State.TURN:
		_change_state(State.IDLE)
	move_yaw = facing_yaw
	model.play(&"idle", 0.15)


## Player_Action_808407CC: standing still in parallel mode.
func _idle_parallel(delta: float) -> void:
	facing_yaw = _step_angle(facing_yaw, parallel_yaw, target_face_step, delta)
	if state == State.TURN:
		_change_state(State.IDLE)
	var target := _stick_speed(false)
	match _parallel_class(target):
		1:
			_start_moving(_stick_yaw, true, ZMove.FORWARD)
			return
		-1:
			_start_moving(_stick_yaw, false, ZMove.BACK)
			return
	if target > 4.9:
		_start_moving(move_yaw, false, ZMove.SIDE)
		return
	if target > 0.0:
		_start_moving(move_yaw, false, ZMove.SIDE_SLOW)
		return
	move_yaw = facing_yaw
	model.play(&"idle", 0.15)


## func_8083C8DC: face the stick immediately and start running.
func _start_moving(yaw: float, snap_facing: bool, zm := ZMove.NONE) -> void:
	if snap_facing:
		facing_yaw = yaw
	move_yaw = yaw
	_change_state(State.MOVE)
	z_move = zm


## Player_Action_80842180 (free run) and Player_Action_8084193C (lock-on movement).
func _state_move(delta: float) -> void:
	if not is_on_floor() and _air_time > 0.05:
		_change_state(State.AIR)
		return
	if _try_actions():
		return
	if not parallel and z_move != ZMove.NONE:
		# Leaving parallel mode: a back-walk turns the body to the walk direction
		# at once (func_8083C8DC); anything else just keeps running.
		if z_move == ZMove.BACK:
			facing_yaw = move_yaw
		z_move = ZMove.NONE
	if lock_target:
		_move_locked(delta)
	elif parallel:
		_move_parallel(delta)
	else:
		var target := _stick_speed(true)
		var yaw_target := _stick_yaw if _stick_mag > 0.0 else move_yaw
		# func_8083C484: pushing far behind the run direction stops dead first.
		if _stick_mag > 0.0 and absf(angle_difference(move_yaw, yaw_target)) > reverse_angle * BINANG:
			speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
			if speed_oot > 0.0:
				_animate_ground()
				return
			target = 0.0
			yaw_target = move_yaw
		# func_8083DF68.
		speed_oot = _asym_step(speed_oot, target, run_accel, run_decel, delta)
		move_yaw = _step_angle(move_yaw, yaw_target, run_turn_step, delta)
		if speed_oot == 0.0 and target == 0.0:
			_change_state(State.IDLE)
	_animate_ground()


## Lock-on movement: the body keeps facing the target while the hero walks,
## side-steps or backs off in the stick direction.
func _move_locked(delta: float) -> void:
	var target := _stick_speed(false) * 0.9
	if target == 0.0:
		speed_oot = _asym_step(speed_oot, 0.0, 2.0, 3.0, delta)
		if speed_oot == 0.0:
			_change_state(State.IDLE)
		return
	var diff := angle_difference(move_yaw, _stick_yaw)
	if absf(diff) > PI / 2.0 and speed_oot > 0.0:
		speed_oot = move_toward(speed_oot, 0.0, 3.0 * _frames(delta))
		if speed_oot == 0.0:
			move_yaw = _stick_yaw
		return
	speed_oot = _asym_step(speed_oot, target, 2.0, 3.0, delta)
	# Turn by a tenth of the remaining angle per frame.
	move_yaw = _step_angle(move_yaw, _stick_yaw, absf(diff) / BINANG * 0.1, delta)


## Parallel-mode movement: the body keeps facing `parallel_yaw` (except when
## walking forward) while the hero walks, side-steps or back-walks.
func _move_parallel(delta: float) -> void:
	var target := _stick_speed(false)
	var cls := _parallel_class(target)
	var yaw_target := _z_yaw_target()
	var diff := angle_difference(move_yaw, yaw_target)
	var f := _frames(delta)
	match z_move:
		ZMove.FORWARD:
			# Player_Action_8084227C: an ordinary run (linear stick speed) that
			# drops back to standing once the stick leaves the forward cone.
			if target != 0.0 and cls <= 0:
				_change_state(State.IDLE)
				return
			if _stick_mag > 0.0 and absf(diff) > reverse_angle * BINANG:
				speed_oot = move_toward(speed_oot, 0.0, stop_decel * f)
				if speed_oot == 0.0:
					_change_state(State.IDLE)
				return
			speed_oot = _asym_step(speed_oot, target, run_accel, run_decel, delta)
			move_yaw = _step_angle(move_yaw, yaw_target, run_turn_step, delta)
			if speed_oot == 0.0 and target == 0.0:
				_change_state(State.IDLE)
		ZMove.SIDE:
			# Player_Action_8084193C.
			if cls > 0:
				z_move = ZMove.FORWARD
			elif cls < 0:
				z_move = ZMove.BACK
				move_yaw = yaw_target
			elif speed_oot < 3.6 and target < 4.0:
				z_move = ZMove.SIDE_SLOW
			elif absf(diff) > PI / 2.0:
				speed_oot = move_toward(speed_oot, 0.0, 3.0 * f)
				if speed_oot == 0.0:
					move_yaw = yaw_target
			else:
				speed_oot = _asym_step(speed_oot, target * 0.9, 2.0, 3.0, delta)
				move_yaw = _step_angle(move_yaw, yaw_target, absf(diff) / BINANG * 0.1, delta)
		ZMove.SIDE_SLOW:
			# Player_Action_80840DE4.
			if cls > 0:
				_start_moving(yaw_target, true, ZMove.FORWARD)
			elif cls < 0:
				z_move = ZMove.BACK
				move_yaw = yaw_target
			elif target > 4.9:
				z_move = ZMove.SIDE
			elif target == 0.0 and speed_oot == 0.0:
				_change_state(State.IDLE)
			elif absf(diff) > PI / 2.0:
				speed_oot = move_toward(speed_oot, 0.0, 1.5 * f)
				if speed_oot == 0.0:
					move_yaw = yaw_target
			else:
				speed_oot = _asym_step(speed_oot, target * 0.4, 1.5, 1.5, delta)
				move_yaw = _step_angle(move_yaw, yaw_target, absf(diff) / BINANG * 0.1, delta)
		ZMove.BACK:
			# Player_Action_808414F8: brake to a stop before changing direction
			# (func_80841458), then walk forward or side-step.
			if cls >= 0:
				if target != 0.0 or speed_oot > 6.0:
					speed_oot = move_toward(speed_oot, 0.0, stop_decel * f)
					if speed_oot > 0.0:
						return
					target = 0.0
				if cls > 0:
					_start_moving(yaw_target, true, ZMove.FORWARD)
				else:
					z_move = ZMove.SIDE if target > 4.9 else ZMove.SIDE_SLOW
				return
			speed_oot = _asym_step(speed_oot, target * 1.5, 1.5, 2.0, delta)
			move_yaw = _step_angle(move_yaw, yaw_target, absf(diff) / BINANG * 0.1, delta)
		_:
			z_move = ZMove.FORWARD


## A, attack, shield, item and first-person handlers, checked from the
## standing and moving states.
func _try_actions() -> bool:
	if is_instance_valid(held):
		# A bomb in hand with the stick at rest: A sets it down at his feet
		# (OoT puts a bomb down instead of throwing it while standing still).
		if input_enabled and is_on_floor() and held is Bomb and Input.is_action_just_pressed("interact") and _stick_dir() == StickDir.NONE:
			combat.clear_buffer()
			_set_down_bomb()
			return true
		# Player_ActionHandler_9: A, B or an item button throws what he carries.
		if input_enabled and is_on_floor() and (Input.is_action_just_pressed("interact") \
				or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("item_x") \
				or Input.is_action_just_pressed("item_y")):
			combat.clear_buffer()
			_start_carry_throw()
			return true
		combat.clear_buffer()
		return false
	if input_enabled and Input.is_action_just_pressed("interact") and _a_action():
		return true
	if input_enabled:
		for b in ["item_x", "item_y"]:
			if Input.is_action_just_pressed(b) and _use_item(b):
				return true
		if Input.is_action_just_pressed("first_person") and _try_look():
			return true
	# Player_CanSpinAttack: the stick swept round, then B: the quickspin (once
	# the Great Spin has been learned).
	if combat.wants_attack() and _can_quickspin() and PlayerCombat.knows(PlayerCombat.TECH_SPIN) \
			and Progress.sword != "" and is_on_floor():
		_end_bow_z()
		combat.clear_buffer()
		_set_sword_drawn(true)
		start_spin()
		return true
	if combat.wants_attack():
		_end_bow_z()
		_begin_attack()
		return true
	# Player_ActionHandler_11: the crouched shield is only for when not Z-targeting.
	if combat.wants_block() and not is_z_targeting():
		_change_state(State.BLOCK)
		return true
	return false


## What A does. Interactables come first (doors, signs and chests will live
## here), then Player_ActionHandler_10 / Player_ActionHandler_Roll.
func _a_action() -> bool:
	var thing := interact_candidate()
	if thing:
		thing.interact(self)
		return true
	var liftable := lift_candidate()
	if liftable and is_on_floor():
		_start_lift(liftable)
		return true
	# The Shield Bash with the shield raised while Z-targeting.
	if _z_shield and is_on_floor() and PlayerCombat.knows(PlayerCombat.TECH_BASH) and not combat.bashing \
			and not Equipment.two_handed():
		_start_bash()
		return true
	# WALL_FLAG_6 surfaces (blocks) are climbed with A instead of automatically.
	if _ledge.get("a_climb", false) and _ledge.get("type", 0) >= 2 and is_on_floor():
		_start_ledge_climb(_ledge)
		return true
	var dir := _stick_dir()
	if is_z_targeting():
		match dir:
			StickDir.NONE, StickDir.FORWARD:
				# Player_ActionHandler_10: a jump slash with the sword in hand,
				# otherwise a roll. Locking on to an enemy readies the sword.
				if sword_drawn or lock_target:
					_start_jumpslash(jumpslash_speed, jumpslash_vy)
				else:
					_start_roll()
			_:
				_start_hop(dir)
		return true
	if dir != StickDir.NONE:
		# Player_TryRoll: the body has turned to the stick, so it is "forward".
		facing_yaw = _stick_yaw
		_start_roll()
		return true
	if can_put_away():
		_change_state(State.SHEATHE)
		model.play(&"sheathe", 0.05, 1.0, true)
		return true
	return false


## True when A would put the sword away (DO_ACTION_PUTAWAY after its cooldown).
func can_put_away() -> bool:
	return _put_away_cooldown <= 0.0 and _put_away_possible()


func _put_away_possible() -> bool:
	return sword_drawn and not is_z_targeting() and not is_shielding() and not is_carrying() \
		and state in [State.IDLE, State.TURN, State.MOVE] and _stick_dir() == StickDir.NONE \
		and interact_candidate() == null


## The A button label for the HUD (OoT's do-action icon): an interactable's
## label, CLIMB, DROP, RETURN, NEXT, PUT AWAY, or "".
func a_action_label() -> String:
	match state:
		State.SWIM:
			return "DIVE" if diving == 0 and interact_candidate() == null else ""
		State.RIDE:
			if riding_aim:
				return "RETURN"
			if is_instance_valid(horse) and horse.can_dismount():
				return "GET OFF"
			return "FASTER"
		State.TALK:
			if fishing and not Dialogue.active and is_instance_valid(FishingSpot.current):
				return FishingSpot.current.a_label()
			return "DECIDE" if Dialogue.phase == Dialogue.Phase.CHOOSING else "NEXT"
		State.LOOK, State.AIM:
			return "RETURN"
		State.HANG, State.LADDER:
			return "DROP"
		State.CLIMB, State.DEAD, State.LIFT, State.THROW:
			return ""
	if is_instance_valid(held):
		return "THROW" if is_on_floor() else ""
	var thing := interact_candidate()
	if thing:
		return String(thing.interact_label()) if thing.has_method("interact_label") else ""
	if lift_candidate():
		return "GRAB"
	if _ledge.get("a_climb", false) and _ledge.get("type", 0) >= 2:
		return "CLIMB"
	# DO_ACTION_ATTACK: Z-targeting with the sword ready, A jump-slashes.
	if is_z_targeting() and (sword_drawn or lock_target) and is_on_floor() 			and state in [State.IDLE, State.TURN, State.MOVE] and _stick_dir() in [StickDir.NONE, StickDir.FORWARD]:
		return "ATTACK"
	return "PUT AWAY" if can_put_away() else ""


func _set_sword_drawn(drawn: bool) -> void:
	sword_drawn = drawn
	model.set_sword_drawn(drawn)


## Player_UpdateInterface's putAwayCooldownTimer and the Z-target shield layer.
func _update_shield_and_sword(delta: float) -> void:
	if _put_away_possible():
		_put_away_cooldown = maxf(_put_away_cooldown - delta, 0.0)
	else:
		_put_away_cooldown = put_away_delay
	var was := _z_shield
	_z_shield = combat.wants_block() and is_z_targeting() and not bow_z and not hook_z \
		and state in [State.IDLE, State.TURN, State.MOVE, State.LAND]
	if _z_shield and not was:
		Sfx.play("shield_block", -14.0)
	if is_shielding() and not sword_drawn and Equipment.two_handed() and Progress.sword != "":
		_set_sword_drawn(true)
	if bow_z:
		_update_bow_z(delta)
	if hook_z:
		_update_hook_z(delta)
	if boom_z:
		_update_boom_z(delta)
	if _throw_time > 0.0:
		_throw_time -= delta
	_update_upper_pose(delta)


## Picks the pose layered over the legs: carrying, the boomerang or bow, a
## throw, or the Z-target shield.
func _update_upper_pose(delta: float) -> void:
	var want := "shield"
	var on := _z_shield
	var two := sword_drawn and Equipment.two_handed()
	if two:
		want = "guard"
		on = _z_shield or state == State.BLOCK
	if fishing:
		want = "fish"
		on = true
	elif is_instance_valid(held) and state != State.LIFT and state != State.THROW:
		want = "carry"
		on = true
	elif _throw_time > 0.0:
		want = "throw"
		on = true
	elif combat.stabbing:
		# The thrust itself plays on the arm (play_upper in _state_block).
		pass
	elif combat.charging:
		want = "charge"
		on = true
	elif combat.bashing and state != State.BLOCK:
		want = "bash"
		on = true
	elif boom_z or (state == State.AIM and aim_item == "boomerang"):
		want = "boom_ready"
		on = true
	elif _ride_swing > 0.0:
		# The cut plays on the upper body (play_upper when it starts).
		pass
	elif bow_z or hook_z or ((state == State.AIM or riding_aim) and aim_item in ["bow", "hookshot", "bloom_rod"]):
		want = "bow"
		on = true
	elif two and not on and not combat.is_attacking() and state in [State.IDLE, State.TURN, State.MOVE, State.LAND]:
		# The greatsword held ready in both hands, point up in front.
		want = "great_ready"
		on = true
	_set_upper(want)
	var blend := 0.05 if combat.stabbing else 0.12
	model.upper_weight = move_toward(model.upper_weight, 1.0 if on else 0.0, delta / blend)
	# Aiming in first person, the chest follows the view up and down.
	var aiming_fp := (state == State.AIM or riding_aim) and aim_item != ""
	model.aim_pitch = lerpf(model.aim_pitch, look_pitch * 0.85 if aiming_fp else 0.0, 1.0 - exp(-18.0 * delta))


func _set_upper(pose_name: String) -> void:
	if pose_name != _upper_name:
		_upper_name = pose_name
		model.set_upper_pose(UPPER_POSES[pose_name])


# --- Swimming ------------------------------------------------------------------

## func_8083D53C: deep enough water starts a swim (func_8083D36C).
func _update_water() -> void:
	_water_y = Surface.water_level(World.area_node, global_position) if is_instance_valid(World.area_node) else NAN
	water_depth = (_water_y - global_position.y) / oot_unit if not is_nan(_water_y) else -1.0
	if state == State.SWIM or water_depth <= SWIM_ENTER:
		return
	if state in [State.CLIMB, State.HANG, State.LADDER, State.DEAD, State.TALK, State.RIDE]:
		return
	# In the Anchor Boots he sinks and walks the bottom instead.
	if Progress.anchor_boots():
		return
	_enter_swim()


func _enter_swim() -> void:
	_reset_actions()
	combat.cancel_attack()
	_clear_z_targeting()
	_set_sword_drawn(false)
	_hop = false
	_jumped = false
	diving = 0
	_stroke = 0.0
	# Falling in keeps a little of the drop, then the water takes over.
	velocity.y = maxf(velocity.y, -_to_mps(5.0))
	_change_state(State.SWIM)
	model.play(&"swim_wait", 0.12)
	Sfx.play("splash_big", -2.0 if _pre_move_vy < -_to_mps(4.0) else -8.0)


## Frostpeak Hollow's cold (areas with "chill" in WorldData.AREAS): without
## the Frost Mantle a countdown runs (shown on the HUD, as OoT shows its heat
## timer in the Fire Temple), and once it is out the cold bites half a heart
## every few seconds. Leaving the cold, or the mantle, resets it.
const CHILL_SECONDS := 90.0
const CHILL_BITE := 3.0
## Seconds left before the cold bites (CHILL_SECONDS when warm).
var chill_left := CHILL_SECONDS
var _chill_bite := 0.0


## True while the cold is counting down on him.
func chilled() -> bool:
	return WorldData.chilly(World.area_id) and not Progress.cold_proof() and not is_dead() and not Cutscene.active


func _update_chill(delta: float) -> void:
	if not chilled():
		chill_left = CHILL_SECONDS
		_chill_bite = 0.0
		return
	if GameManager.state != GameManager.GameState.PLAYING or Dialogue.active:
		return
	chill_left = maxf(chill_left - delta, 0.0)
	if chill_left > 0.0:
		return
	_chill_bite -= delta
	if _chill_bite <= 0.0:
		_chill_bite = CHILL_BITE
		health.apply_damage(1)
		model.flash(Color(0.7, 0.9, 1.0), 0.15)
		Sfx.play("player_hurt", -6.0, 0.05, 1.2)


## The Anchor Boots (Chapter IV): heavy on land, heavier under water. Walking
## the bottom without the Tide Tunic he holds his breath for ANCHOR_BREATH
## seconds, then the water takes half a heart every ANCHOR_BITE.
const ANCHOR_BREATH := 10.0
const ANCHOR_BITE := 2.0
var breath_left := ANCHOR_BREATH
var _anchor_bite := 0.0


## Under water in the Anchor Boots, head and all.
func underwater_walking() -> bool:
	return Progress.anchor_boots() and not is_nan(_water_y) and _water_y > global_position.y + 1.5


func anchor_slow() -> float:
	if not Progress.anchor_boots() or state == State.SWIM:
		return 1.0
	return 0.55 if underwater_walking() else 0.8


func _update_anchor(delta: float) -> void:
	if not underwater_walking() or Progress.breathes_water() or is_dead():
		breath_left = ANCHOR_BREATH
		_anchor_bite = 0.0
		return
	# Sinking slowly, as through water, not falling.
	velocity.y = maxf(velocity.y, -_to_mps(3.0))
	if GameManager.state != GameManager.GameState.PLAYING or Dialogue.active or Cutscene.active:
		return
	breath_left = maxf(breath_left - delta, 0.0)
	if breath_left > 0.0:
		return
	_anchor_bite -= delta
	if _anchor_bite <= 0.0:
		_anchor_bite = ANCHOR_BITE
		health.apply_damage(1)
		model.flash(Color(0.6, 0.8, 1.0), 0.15)
		Sfx.play("player_hurt", -6.0, 0.05, 0.9)


## True while swimming (on the surface or diving).
func is_swimming() -> bool:
	return state == State.SWIM


func _state_swim(delta: float) -> void:
	var f := _frames(delta)
	# Anchor Boots put on in the water: down he goes.
	if Progress.anchor_boots():
		diving = 0
		_change_state(State.AIR)
		model.play(&"fall", 0.15)
		return
	# Out of the water's reach: wading again (func_8083D0A8).
	if water_depth < SWIM_EXIT:
		diving = 0
		velocity.y = 0.0
		_change_state(State.MOVE if _stick_speed(false) > 0.0 else State.IDLE)
		model.play(&"idle", 0.15)
		return
	var vy := velocity.y / _to_mps(1.0)
	if diving == 1:
		# func_8084DBC4: down while A is held, to the dive's depth.
		if input_enabled and Input.is_action_pressed("interact") and water_depth < Progress.dive_depth() and not is_on_floor():
			vy = move_toward(vy, -2.0, 0.5 * f)
		elif input_enabled and Input.is_action_pressed("interact") and Progress.breathes_water():
			# In the Tide Tunic he stays down while A is held, as long as he likes.
			vy = move_toward(vy, 0.0, 0.5 * f)
		else:
			diving = 2
	elif diving == 2:
		vy = move_toward(vy, minf(water_depth * 0.018 + 4.0, 8.0), 0.5 * f)
		if water_depth < SWIM_SURFACE and vy > 0.0:
			diving = 0
			Sfx.play("step_water_1", -4.0, 0.05, 0.8)
	else:
		vy = _buoyancy(vy, f)
		if input_enabled and Input.is_action_just_pressed("interact") and interact_candidate() == null:
			diving = 1
			vy = -1.0
			Sfx.play("splash_big", -8.0, 0.05, 1.3)
	velocity.y = _to_mps(vy)
	# The stroke: speed builds only while the arms push (frames 10-20).
	var target := _stick_speed(false)
	var yaw_target := _stick_yaw if _stick_mag > 0.0 else move_yaw
	if target > 0.0 and absf(angle_difference(move_yaw, yaw_target)) > reverse_angle * BINANG:
		speed_oot = move_toward(speed_oot, 0.0, 1.0 * f)
		if speed_oot == 0.0:
			move_yaw = yaw_target
		target = 0.0
	var rate := maxf(speed_oot * 0.5, 1.0) * OOT_RATE
	var before := _stroke
	_stroke = fmod(_stroke + rate * f, STROKE_FRAMES)
	if _stroke < before and target > 0.0:
		Sfx.play("swim_stroke", -10.0, 0.08)
	var push := _stroke - 10.0
	var accel := push * 6.0 if push > 0.0 and push < 10.0 else 0.0
	if accel <= 0.0:
		target = 0.0
	speed_oot = minf(speed_oot, run_speed_limit * 0.8)
	speed_oot = _asym_step(speed_oot, target * 0.8, accel, absf(speed_oot) * 0.02 + 0.05, delta)
	move_yaw = _step_angle(move_yaw, yaw_target, 1600.0, delta)
	facing_yaw = move_yaw
	if diving > 0:
		model.play(&"dive", 0.15)
	elif _stick_mag > 0.0 or speed_oot > 0.5:
		model.play(&"swim", 0.15, maxf(speed_oot * 0.5, 1.0) / 1.0)
	else:
		model.play(&"swim_wait", 0.2)
	# Pushing against a low bank: climb out.
	if diving == 0 and _facing_wall(_wall) and _stick_mag > 30.0:
		var ledge := _probe_ledge(_wall)
		if not ledge.is_empty() and ledge.y > _water_y - 0.2:
			diving = 0
			_climb_kind = Climb.STEP_HIGH
			_climb_time = step_high_time
			_start_ledge_climb_from_water(ledge)


## func_8084B000: the water pulls him to floating depth.
func _buoyancy(vy: float, f: float) -> float:
	var float_depth := SWIM_FLOAT + (1.0 if vy < 0.0 else 0.0)
	if water_depth < float_depth:
		var drag := (vy * 0.5 if vy > 0.0 else 0.0)
		vy = maxf(vy + (-0.1 - drag) * f, -5.0)
	else:
		var lift := (-vy * 0.3 if vy < 0.0 else 0.0)
		vy = minf(vy + (lift + 0.1) * f, 2.0)
	return vy


func _start_ledge_climb_from_water(ledge: Dictionary) -> void:
	facing_yaw = _yaw_of(-ledge.n)
	move_yaw = facing_yaw
	rotation.y = facing_yaw
	_ledge = ledge
	_climb_onto(ledge, &"climb_high")
	Sfx.play("splash_big", -10.0, 0.05, 1.4)


# --- Riding --------------------------------------------------------------------

func is_riding() -> bool:
	return state == State.RIDE and is_instance_valid(horse)


func is_riding_aim() -> bool:
	return riding_aim


## The stick as the horse reads it (0-60 and a world yaw).
func stick_magnitude() -> float:
	return _stick_mag


func stick_world_yaw() -> float:
	return _stick_yaw


## The stick's angle as the horse reads it (EnHorse_StickDirection): the raw
## stick's angle from straight up, so up is "on ahead" and right is "turn
## right" whatever the camera is doing. A scripted world direction is taken
## relative to her heading `horse_yaw` instead.
func ride_stick_angle(horse_yaw: float) -> float:
	if _stick_mag <= 0.0:
		return 0.0
	if _stick_raw == Vector2.INF:
		return angle_difference(horse_yaw, _stick_yaw)
	return atan2(-_stick_raw.x, _stick_raw.y)


## Climbs into the saddle.
func mount(h: Horse, instant := false) -> void:
	_reset_actions()
	_clear_z_targeting()
	combat.cancel_attack()
	_set_sword_drawn(false)
	var old := focus_position()
	horse = h
	riding_aim = false
	_ride_swing = 0.0
	h.on_mounted(self)
	_change_state(State.RIDE)
	_place_on_horse()
	model.play(&"ride", 0.05 if instant else 0.15)
	if not instant:
		_start_model_offset(old - global_position, 0.35, false)
		Sfx.play("jump", -6.0)


## Gets off on her left side.
func dismount() -> void:
	if horse == null:
		return
	var h := horse
	horse = null
	_leave_ride_aim()
	_ride_swing = 0.0
	combat.sword_hitbox.deactivate()
	h.on_dismounted()
	var old := focus_position()
	var spot := h.global_position + h.global_basis * Vector3(-1.2, 0, 0)
	var hit := _ray(spot + Vector3.UP * 2.0, spot + Vector3.DOWN * 3.0)
	if not hit.is_empty():
		spot.y = hit.position.y
	global_position = spot + Vector3.UP * 0.05
	velocity = Vector3.ZERO
	speed_oot = 0.0
	facing_yaw = h.yaw
	move_yaw = facing_yaw
	rotation.y = facing_yaw
	_change_state(State.IDLE)
	_start_model_offset(old - global_position, 0.3, false)
	model.play(&"land", 0.05, 1.0, true)


func _place_on_horse() -> void:
	var t := horse.seat_transform()
	global_position = t.origin - Vector3(0, 0.85, 0)
	if not riding_aim:
		facing_yaw = horse.yaw
	move_yaw = facing_yaw
	rotation.y = facing_yaw


func _state_ride(delta: float) -> void:
	if not is_instance_valid(horse):
		horse = null
		riding_aim = false
		_change_state(State.AIR)
		return
	speed_oot = 0.0
	_place_on_horse()
	if _ride_swing > 0.0:
		_ride_swing -= delta
		if _ride_swing < 0.32 and _ride_swing + delta >= 0.32:
			combat.sword_hitbox.activate()
			Sfx.play("sword_swing", -4.0)
		if _ride_swing < 0.18:
			combat.sword_hitbox.deactivate()
	if riding_aim:
		_update_look(delta, true)
		_update_aim_target()
		_update_bow(delta, true)
		model.play(&"ride", 0.15)
		if input_enabled and (Input.is_action_just_pressed("interact") or (Input.is_action_just_pressed("attack") \
				and not Input.is_action_just_pressed("aim_fire")) or Input.is_action_just_pressed("first_person")):
			combat.clear_buffer()
			_leave_ride_aim()
		return
	var galloping := horse.gait == Horse.Gait.GALLOP or horse.mode == Horse.Mode.JUMP
	model.play(&"ride_gallop" if galloping else &"ride", 0.15)
	if not input_enabled:
		combat.clear_buffer()
		return
	if Input.is_action_just_pressed("interact"):
		if horse.can_dismount():
			dismount()
			return
		horse.spur()
	if combat.wants_attack() and _ride_swing <= 0.0:
		combat.clear_buffer()
		_set_sword_drawn(true)
		_ride_swing = 0.42
		model.play_upper(&"slash_left", RIDE_SLASH_PATHS)
	for b in ["item_x", "item_y"]:
		var on_b := Progress.item_on(b)
		if Input.is_action_just_pressed(b) and (on_b == "bow" or PlayerItems.arrow_kind(on_b) != ""):
			if Progress.arrows <= 0:
				Sfx.play("error", -6.0)
				continue
			arrow_kind = PlayerItems.arrow_kind(on_b)
			_aim_button = b
			riding_aim = true
			aim_item = "bow"
			look_yaw = facing_yaw
			look_pitch = 0.0
			GameManager.take_mouse_motion()
			model.set_bow_out(true)
			_bow_ready()
			Sfx.play("bow_draw", -6.0)
			return


func _leave_ride_aim() -> void:
	if not riding_aim:
		return
	riding_aim = false
	bow_phase = Bow.NONE
	aim_item = ""
	model.set_bow_out(false)
	if camera_rig:
		camera_rig.snap_behind_target()


## Used only by the automatic ledge jump; A never jumps.
func _jump(vy_oot: float, anim: StringName) -> void:
	velocity.y = _to_mps(vy_oot)
	_jumped = true
	_hop = false
	_change_state(State.AIR)
	model.play(anim, 0.04, 1.0, true)
	Sfx.play("jump", -6.0)


## func_8083BCD0: side hop or back flip while locked on.
func _start_hop(dir: StickDir) -> void:
	_hop_dir = dir
	var back := dir == StickDir.BACK
	velocity.y = _to_mps(backflip_velocity_oot if back else sidehop_velocity_oot)
	speed_oot = backflip_speed if back else sidehop_speed
	# Left is +90 deg in Godot yaw (counter-clockwise seen from above).
	match dir:
		StickDir.LEFT: move_yaw = facing_yaw + PI / 2.0
		StickDir.RIGHT: move_yaw = facing_yaw - PI / 2.0
		_: move_yaw = facing_yaw + PI
	_jumped = true
	_hop = true
	_change_state(State.AIR)
	var anim := &"backflip" if back else (&"sidehop_l" if dir == StickDir.LEFT else &"sidehop_r")
	model.play(anim, 0.03, 1.0, true)
	Sfx.play("jump", -6.0)


func _start_roll() -> void:
	move_yaw = facing_yaw
	_change_state(State.ROLL)
	model.play(&"roll", 0.03, 1.0, true)
	Sfx.play("land", -6.0)


## Player_Action_Roll: 1.5x the walking speed for the stick (at least 3) along
## the facing; bonks off walls when faster than 7.
func _state_roll(delta: float) -> void:
	if _state_time >= roll_invuln_start and _state_time - delta < roll_invuln_start:
		_invuln_time = maxf(_invuln_time, roll_invuln_time)
		_blink_time = -1000.0   # roll invulnerability does not blink
	var target := _stick_speed(true) * 1.5
	if target < 3.0 or _stick_dir() != StickDir.FORWARD:
		target = 3.0
	speed_oot = _asym_step(speed_oot, target, run_accel, run_decel, delta)
	move_yaw = _step_angle(move_yaw, facing_yaw, run_turn_step, delta)
	if speed_oot >= roll_bonk_speed and is_on_wall():
		var n := get_wall_normal()
		if n.dot(-forward()) > cos(PI / 4.0):
			_bonk()
			return
	if not is_on_floor() and _air_time > 0.05:
		_change_state(State.AIR)
		return
	if _state_time >= roll_time:
		_change_state(State.MOVE if _stick_speed(true) > 0.0 else State.IDLE)


func _bonk() -> void:
	move_yaw = facing_yaw + PI
	speed_oot = clampf(speed_oot, 0.0, 6.0) * 0.5
	_change_state(State.BONK)
	model.play(&"bonk", 0.02, 1.0, true)
	Sfx.play("shield_block", -2.0)
	GameManager.rumble(1.0, 0.45)
	if camera_rig:
		camera_rig.shake(0.12, 0.35)


## Player_Action_8084411C with func_8083DFE0: very little air control.
func _state_air(delta: float) -> void:
	# The Down Thrust: B while dropping from a height drives the blade down.
	if combat.wants_attack() and _can_thrust():
		_start_thrust()
		return
	# func_8083BBA0: B in mid-air turns any jump but the back flip into a jump slash.
	if combat.wants_attack() and not is_carrying() and not (_hop and _hop_dir == StickDir.BACK):
		_start_jumpslash(air_jumpslash_speed, air_jumpslash_vy)
		return
	if not _hop:
		speed_oot = clampf(speed_oot, -run_speed_limit, run_speed_limit)
		var target := _stick_speed(false)
		var yaw_target := _stick_yaw if _stick_mag > 0.0 else move_yaw
		if absf(angle_difference(move_yaw, yaw_target)) > reverse_angle * BINANG:
			speed_oot = move_toward(speed_oot, 0.0, 1.0 * _frames(delta))
			if speed_oot == 0.0:
				move_yaw = yaw_target
		else:
			speed_oot = _asym_step(speed_oot, target, air_accel, air_decel, delta)
			move_yaw = _step_angle(move_yaw, yaw_target, air_turn_step, delta)
	if _hop or (velocity.y > 0.0 and model.current_anim == &"jump"):
		return
	model.play(&"fall", 0.12)


## func_8083BA90: leap along the facing with the sword raised.
func _start_jumpslash(xz_speed: float, vy: float) -> void:
	if lock_target:
		_face_toward(lock_target.global_position, 1e9, 1.0)
	elif parallel:
		facing_yaw = parallel_yaw
	move_yaw = facing_yaw
	speed_oot = xz_speed
	velocity.y = _to_mps(vy)
	_jumped = true
	_hop = false
	_js_landed = false
	_set_sword_drawn(true)
	_change_state(State.JUMPSLASH)
	combat.start_jumpslash()
	model.play(&"jumpslash", 0.03, 1.0, true)
	Sfx.play("jump", -6.0)


## Player_Action_80844AF4 in the air, then the finishing chop on the ground.
func _state_jumpslash(delta: float) -> void:
	if _thrust:
		_state_thrust(delta)
		return
	if not _js_landed:
		combat.jumpslash_hit(_state_time >= jumpslash_hit_start)
		# func_8083DFE0 with the linear stick speed, as in any jump.
		var target := _stick_speed(false)
		var yaw_target := _stick_yaw if _stick_mag > 0.0 else move_yaw
		if absf(angle_difference(move_yaw, yaw_target)) > reverse_angle * BINANG:
			speed_oot = move_toward(speed_oot, 0.0, 1.0 * _frames(delta))
			if speed_oot == 0.0:
				move_yaw = yaw_target
		else:
			speed_oot = _asym_step(speed_oot, target, air_accel, air_decel, delta)
			move_yaw = _step_angle(move_yaw, yaw_target, air_turn_step, delta)
		if is_on_floor() and _state_time > 0.05:
			# func_80843E64, then PLAYER_MWA_JUMPSLASH_FINISH.
			_js_landed = true
			_jumped = false
			_state_time = 0.0
			_footstep(true, 10.0)
			combat.jumpslash_land()
			model.play(&"jumpslash_land", 0.02, 1.0, true)
			Sfx.play("sword_swing", -3.0, 0.03, 0.75)
			GameManager.rumble(0.3, 0.1)
		return
	# Math_StepToF(speedXZ, 0, 1) per frame on landing.
	speed_oot = move_toward(speed_oot, 0.0, 1.0 * _frames(delta))
	move_yaw = facing_yaw
	if _state_time >= jumpslash_land_hit:
		combat.jumpslash_hit(false)
	if not is_on_floor() and _air_time > 0.1:
		_change_state(State.AIR)
		return
	if _state_time >= jumpslash_land_time:
		_change_state(State.IDLE)


## Whether B in the air now would be a Down Thrust: the technique learned, a
## sword in hand, falling (not rising off a hop), and high enough above the
## ground below.
func _can_thrust() -> bool:
	if not PlayerCombat.knows(PlayerCombat.TECH_THRUST) or Progress.sword == "" or is_carrying() or _hop:
		return false
	if velocity.y > 0.5:
		return false
	var from := global_position + Vector3.UP * 0.2
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 40.0, 1)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or global_position.y - (hit.position as Vector3).y >= THRUST_MIN_DROP


func _start_thrust() -> void:
	speed_oot = 0.0
	move_yaw = facing_yaw
	velocity.y = minf(velocity.y, -4.0)
	_thrust = true
	_js_landed = false
	_hop = false
	_set_sword_drawn(true)
	_change_state(State.JUMPSLASH)
	combat.start_thrust()
	model.play(&"jumpslash_land", 0.06, 0.4, true)


## Straight down, blade first; the shock where he lands, then up again.
func _state_thrust(delta: float) -> void:
	speed_oot = 0.0
	move_yaw = facing_yaw
	if not _js_landed:
		velocity.y = -THRUST_FALL
		if is_on_floor() and _state_time > 0.02:
			_js_landed = true
			_jumped = false
			_state_time = 0.0
			_footstep(true, 12.0)
			combat.thrust_land()
			model.play(&"jumpslash_land", 0.02, 1.0, true)
		return
	if not is_on_floor() and _air_time > 0.1:
		# The floor broke under him (a floor seal): keep falling, blade down.
		_js_landed = false
		combat.start_thrust()
		return
	if _state_time >= THRUST_RECOVER:
		_change_state(State.IDLE)


## The Great Spin (PlayerCombat.start_spin): a full circle from where he faces.
func start_spin() -> void:
	if not sword_drawn or state == State.DEAD:
		return
	_spin_from = facing_yaw
	speed_oot = 0.0
	combat.start_spin()
	_change_state(State.ATTACK)


## The Shield Bash: a shove behind the raised shield.
func _start_bash() -> void:
	combat.start_bash()
	speed_oot = 7.0
	move_yaw = facing_yaw
	if state == State.BLOCK:
		model.play(&"block_crouch_hit", 0.02, 1.4, true)


## Takes out or puts away Mira's rod (the sword stays on his back).
func set_fishing(on: bool) -> void:
	fishing = on
	if on:
		_set_sword_drawn(false)
	if _rod == null and on:
		var hand := model.get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
		if hand:
			_rod = MeshInstance3D.new()
			_rod.name = "FishingRod"
			_rod.mesh = load("res://assets/models/fishing_rod_mesh.tres")
			_rod.position = Vector3(0, -0.08, 0)
			hand.add_child(_rod)
	if _rod:
		_rod.visible = on


## The end of the fishing rod, where the line hangs from.
func rod_tip() -> Vector3:
	if _rod and _rod.visible:
		return _rod.global_transform * Vector3(0, 0, -2.1)
	return global_position + Vector3.UP * 2.0 + forward() * 1.5


## The sword rang off a wall (func_80842DF4): thrown back with speedXZ -14.
func sword_recoil() -> void:
	move_yaw = facing_yaw
	speed_oot = -14.0 if state == State.ATTACK else -6.0
	if camera_rig:
		camera_rig.shake(0.05, 0.15)


func _state_attack(delta: float) -> void:
	if combat.spinning:
		speed_oot = 0.0
		facing_yaw = _spin_from + TAU * clampf(combat._tech_t / PlayerCombat.SPIN_TIME, 0.0, 1.0)
		move_yaw = facing_yaw
		return
	if not combat.is_attacking() and combat.charging:
		_change_state(State.IDLE)
		return
	# Small forward lunge during the swing, then plant the feet.
	# (No lunge once the blade has rung off a wall: the recoil wins.)
	var lunge := combat.lunge_speed / _to_mps(1.0) if combat.attack_time < combat.hit_end and not combat.clinked else 0.0
	# A cut's step dies away as OoT's does (Math_StepToF(&speedXZ, 0, 5)).
	var decel := 5.0 * OOT_RATE if speed_oot > lunge else stop_decel
	speed_oot = move_toward(speed_oot, lunge, decel * _frames(delta))
	move_yaw = facing_yaw
	if lock_target:
		_face_toward(lock_target.global_position, target_face_step, delta)
		move_yaw = facing_yaw
	elif parallel:
		facing_yaw = _step_angle(facing_yaw, parallel_yaw, target_face_step, delta)
		move_yaw = facing_yaw
	if not combat.is_attacking():
		_change_state(State.IDLE)


## Player_Action_80843188: crouched behind the shield with the feet planted.
## Z-targeting ends it; the shield then stays up on the upper body instead.
func _state_block(delta: float) -> void:
	if not combat.wants_block() or is_z_targeting():
		_change_state(State.IDLE)
		return
	if not combat.bashing:
		speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
	move_yaw = facing_yaw
	_aim_shield(delta)
	# The Shield Bash: A shoves the shield forward.
	if input_enabled and Input.is_action_just_pressed("interact") and PlayerCombat.knows(PlayerCombat.TECH_BASH) \
			and not combat.bashing and not is_carrying() and not Equipment.two_handed():
		_start_bash()
	if combat.bashing:
		speed_oot = move_toward(speed_oot, 0.0, 1.0 * _frames(delta))
	# func_808428D8: B stabs along the aimed shield (it needs a sword).
	if combat.wants_attack() and Progress.sword != "" and not is_carrying():
		_set_sword_drawn(true)
		combat.start_stab(shield_aim.x)
		model.play_upper(&"stab", ARM_R_PATHS, 0.36 / PlayerCombat.STAB_TIME)
	if model.current_anim != &"block_crouch_hit" or model.animation_finished():
		model.play(&"block_crouch", 0.05)


## The stick, turned into the hero's own frame, tilts and turns the shield;
## each OoT frame closes a quarter of the gap (at least 100 / 50 binang).
func _aim_shield(delta: float) -> void:
	var rel := angle_difference(facing_yaw, _stick_yaw) if _stick_mag > 0.0 else 0.0
	var fwd := _stick_mag * cos(rel)
	var left := _stick_mag * sin(rel)
	var pitch_to := minf(fwd * SHIELD_AIM_PITCH, SHIELD_AIM_PITCH_DOWN) * BINANG
	var yaw_to := left * SHIELD_AIM_YAW * BINANG
	var frames := _frames(delta) * OOT_RATE
	var pitch_step := maxf(absf(pitch_to - shield_aim.y) * 0.25, 100.0 * BINANG) * frames
	var yaw_step := maxf(absf(yaw_to - shield_aim.x) * 0.25, 50.0 * BINANG) * frames
	shield_aim.y = move_toward(shield_aim.y, pitch_to, pitch_step)
	shield_aim.x = move_toward(shield_aim.x, yaw_to, yaw_step)
	model.upper_turn = shield_aim


func _begin_attack() -> void:
	var kind := _melee_kind()
	_aim_swing()
	# B with the sword sheathed draws it straight into the swing.
	_set_sword_drawn(true)
	combat.start_attack(kind)
	_change_state(State.ATTACK)


## func_80837818: which cut B makes, from the stick in the hero's own frame
## (read before he turns to it) and Z-targeting. Standing still he cuts
## across (the forehand); running he chops (OoT's stick-forward STAB turns
## into FORWARD_SLASH without Z); Z-targeting with the stick still he chops,
## with it forward he thrusts, and to either side he cuts that way. Pulled
## back, it is the forehand (D_80854480).
func _melee_kind() -> String:
	var z := is_z_targeting()
	match _stick_dir():
		StickDir.NONE:
			return "slash_down" if z else "slash_left"
		StickDir.FORWARD:
			return "stab" if z else "slash_down"
		StickDir.RIGHT:
			return "slash_right"
	return "slash_left"


## Turns the cut toward the stick (or the locked target) as it starts.
func _aim_swing() -> void:
	if lock_target:
		_face_toward(lock_target.global_position, 1e9, 1.0)
	elif parallel:
		facing_yaw = parallel_yaw
	elif _stick_mag > 18.0:
		facing_yaw = _stick_yaw
	move_yaw = facing_yaw


## PlayerCombat asks for the next cut of a chain (Player_ActionHandler_7
## picks it afresh each time).
func chain_swing() -> String:
	var kind := _melee_kind()
	_aim_swing()
	return kind


## A cut's forward step, in OoT units per frame (the stab's speedXZ = 15).
func swing_step(speed: float) -> void:
	speed_oot = maxf(speed_oot, speed)
	move_yaw = facing_yaw


func _decelerate_velocity(delta: float, rate: float) -> void:
	var h := Vector2(velocity.x, velocity.z).move_toward(Vector2.ZERO, rate * delta)
	velocity.x = h.x
	velocity.z = h.y
	speed_oot = h.length() / _to_mps(1.0)


func _update_air_transitions(was_on_floor: bool) -> void:
	if is_on_floor():
		_air_time = 0.0
		if state == State.AIR and _state_time > 0.05:
			_footstep(true, -_pre_move_vy)
			var hop := _hop
			_hop = false
			_jumped = false
			_land_hold = land_time
			if not hop and _land_from_fall((_fall_start_y - global_position.y) / oot_unit):
				return
			if hop or -_pre_move_vy > hard_landing_speed:
				speed_oot = 0.0 if not hop else speed_oot * 0.3
				_change_state(State.LAND)
				model.play(&"land", 0.03, 1.0, true)
			else:
				_change_state(State.MOVE if speed_oot > 0.0 else State.IDLE)
		return
	_air_time += get_physics_process_delta_time()
	if not was_on_floor or _jumped or velocity.y > 0.0:
		return
	# Running off a ledge faster than 3: OoT jumps automatically, harder at full speed.
	if state in [State.MOVE, State.ROLL] and speed_oot > 3.0 and _drop_below() > ledge_jump_min_drop:
		var vy := 7.5 if speed_oot > 5.9 else 1.25 + 0.2 * speed_oot
		_jump(vy, &"jump")
	# Slower, over a drop of more than 70 units: turn round and hang from the edge.
	elif state in [State.MOVE, State.IDLE, State.TURN] and not is_z_targeting() and not is_carrying() \
			and _drop_straight_down() > HANG_CLEARANCE * oot_unit:
		_try_edge_hang()


## The landing after a fall of `fall` OoT units (Player_Action_8084411C, then
## func_80843E64). Not locked on, past 80 with the stick held forward, he rolls
## out of it, and below 800 the roll saves him the damage. Otherwise from 400 he
## lands hard: half a heart (a heart from 800), the landing_damage crouch, a
## quake and 40 frames of intangibility. True when it took over the landing.
func _land_from_fall(fall: float) -> bool:
	if in_cutscene or state == State.DEAD:
		return false
	if lock_target == null and fall > FALL_ROLL and fall < FALL_HURT_BIG \
			and _stick_dir() == StickDir.FORWARD and not is_carrying():
		_start_roll()
		return true
	if fall < FALL_HURT:
		return false
	speed_oot = 0.0
	_land_hold = LAND_HARD_TIME
	_change_state(State.LAND)
	model.play(&"land_hard", 0.03, 1.0, true)
	health.apply_damage(2 if fall >= FALL_HURT_BIG else 1)
	Sfx.play("player_hurt")
	Sfx.play("land", 0.0, 0.0, 0.7)
	GameManager.rumble(1.0 if fall >= FALL_HURT_BIG else 0.7, 0.4)
	if camera_rig:
		camera_rig.shake(0.1, 0.4)
	_invuln_time = maxf(_invuln_time, LAND_HARD_INVULN)
	_blink_time = 0.0
	return true


# --- Slippery slopes and the quickspin -----------------------------------------------

## True on a slippery slope: OoT's FLOOR_EFFECT_1 polygons. Only ground flagged
## for it slides (a collision shape, or its body, with the meta "slippery");
## steepness alone never does, so ordinary hills and cliff paths stay walkable.
func _on_slippery() -> bool:
	if not is_on_floor() or get_floor_normal().y > 0.995:
		return false
	var hit := _ray(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.6)
	if hit.is_empty():
		return false
	var shape := Hookshot._hit_shape(hit)
	if shape and shape.has_meta("slippery"):
		return bool(shape.get_meta("slippery"))
	var body := hit.collider as Node
	return body != null and bool(body.get_meta("slippery", false))


## func_8083E4C4's slope check, for the ground actions: moving down a slippery
## slope (within 0x3E80 of straight down it) or standing on it, he slips and
## slides; climbing it or crossing it, it pushes him back by (1 - normal.y) * 40.
func _check_slope(delta: float) -> void:
	var f := _frames(delta)
	if not (state in [State.IDLE, State.TURN, State.MOVE]) or in_cutscene or not _on_slippery():
		_push_speed = move_toward(_push_speed, 0.0, 1.2 * f)
		return
	var n := get_floor_normal()
	var down_yaw := _yaw_of(Vector3(n.x, 0.0, n.z))
	var flat := Vector2(velocity.x, velocity.z)
	var vel_yaw := _yaw_of(Vector3(flat.x, 0.0, flat.y)) if flat.length() > 0.05 else down_yaw
	if absf(angle_difference(vel_yaw, down_yaw)) > 0x3E80 * BINANG:
		var slow := (1.0 - n.y) * 40.0
		_push_yaw = down_yaw
		_push_speed = move_toward(_push_speed, slow, maxf(slow * slow * 0.015, 1.2) * f)
		return
	_start_slide(vel_yaw, down_yaw)


func _start_slide(vel_yaw: float, down_yaw: float) -> void:
	combat.end_charge()
	_slide_up = absf(angle_difference(facing_yaw, down_yaw)) > PI * 0.5
	speed_oot = Vector2(velocity.x, velocity.z).length() / _to_mps(1.0)
	move_yaw = vel_yaw
	_push_speed = 0.0
	_change_state(State.SLIDE)
	model.play(&"slope_slip_up" if _slide_up else &"slope_slip", 0.12)
	Sfx.play("land", -8.0, 0.05, 0.6)


## Player_Action_SlideOnSlope: speed builds toward (1 - normal.y) * 40 (at most
## 10) down the slope and the body turns to face down it (or up it, if he
## slipped facing uphill). Off the slippery ground he stops within a frame or
## two and gets up.
func _state_slide(delta: float) -> void:
	if not is_on_floor() and _air_time > 0.1:
		_change_state(State.AIR)
		return
	var f := _frames(delta)
	var n := get_floor_normal() if is_on_floor() else Vector3.UP
	var down := Vector3(n.x, 0.0, n.z)
	var down_yaw := _yaw_of(down) if down.length() > 0.001 else move_yaw
	var target := clampf((1.0 - n.y) * 40.0, 0.0, 10.0)
	var incr := maxf(target * target * 0.015, 1.0)
	var decr := n.y * 0.01
	if not _on_slippery():
		target = 0.0
		decr = n.y * 10.0
	speed_oot = _asym_step(speed_oot, target, incr, decr, delta)
	# Math_SmoothStepToS(yaw, downwardSlopeYaw, 10, 4000, 800).
	var d := angle_difference(move_yaw, down_yaw)
	var step := clampf(absf(d) / 10.0, 800.0 * BINANG, 4000.0 * BINANG) * f
	move_yaw += clampf(d, -step, step)
	facing_yaw = _step_angle(facing_yaw, down_yaw + (PI if _slide_up else 0.0), 2000.0, delta)
	model.play(&"slope_slip_up" if _slide_up else &"slope_slip", 0.12)
	if speed_oot <= 0.0 and target == 0.0:
		_land_hold = 0.3
		_change_state(State.LAND)
		model.play(&"land", 0.08, 0.6, true)


## Player_ProcessControlStick: one sample per OoT frame of the stick's angle in
## 128ths of a turn, or -1 below a push of 55.
func _sample_spin(delta: float) -> void:
	_spin_sample += delta
	while _spin_sample >= 1.0 / OOT_FPS:
		_spin_sample -= 1.0 / OOT_FPS
		var a := -1
		if _stick_mag >= 55.0:
			a = (int(round(_stick_yaw / BINANG)) + 0x2000) & 0xFFFF
			a >>= 9
		_spin_angles.pop_front()
		_spin_angles.append(a)


## Player_CanSpinAttack: the stick swept round (four samples, each at least
## QUICKSPIN_STEP on from the last, all the same way). B then quickspins.
func _can_quickspin() -> bool:
	var sign0 := 0
	for i in 3:
		var a := _spin_angles[i]
		var b := _spin_angles[i + 1]
		if a < 0 or b < 0:
			return false
		var d := wrapi(b - a, -64, 64)
		if absi(d) < QUICKSPIN_STEP or (sign0 != 0 and signi(d) != sign0):
			return false
		sign0 = signi(d)
	return true


## Distance from the feet to the ground slightly ahead, or a large number.
func _drop_below() -> float:
	var from := global_position + forward() * 0.3 + Vector3.UP * 0.2
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 4.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return 99.0 if hit.is_empty() else global_position.y - hit.position.y


## Distance from the feet straight down to the ground (OoT sYDistToFloor).
func _drop_straight_down() -> float:
	var hit := _ray(global_position + Vector3.UP * 0.1, global_position + Vector3.DOWN * 30.0)
	return 99.0 if hit.is_empty() else global_position.y - hit.position.y


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q)


# --- Ledges, hanging and ladders ------------------------------------------------

## The near-vertical world surface the last move pushed into, or {}.
func _touched_wall() -> Dictionary:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var n := c.get_normal()
		if absf(n.y) > WALL_MAX_NY:
			continue
		var body := c.get_collider() as CollisionObject3D
		if body == null or (body.collision_layer & 1) == 0:
			continue
		return {"n": Vector3(n.x, 0, n.z).normalized(), "point": c.get_position(), "shape": c.get_collider_shape()}
	return {}


## sShapeYawToTouchedWall < 0x3000: the hero faces into the wall.
func _facing_wall(w: Dictionary) -> bool:
	return not w.is_empty() and absf(angle_difference(facing_yaw, _yaw_of(-w.n))) < WALL_FACE * BINANG


static func _shape_meta(shape: Object, key: String) -> bool:
	return shape is Node and (shape as Node).get_meta(key, false)


## The CollisionShape3D node a ray hit.
static func _hit_shape(hit: Dictionary) -> Object:
	var body := hit.get("collider") as CollisionObject3D
	if body == null:
		return null
	return body.shape_owner_get_owner(body.shape_find_owner(hit.shape))


## Player_UpdateBgcCheck's ledge probe against the touched wall `w`. Returns {}
## or {type 1-4, y (top), ydist (units), n, point, a_climb}.
func _probe_ledge(w: Dictionary) -> Dictionary:
	var u := oot_unit
	var n: Vector3 = w.n
	var pos := global_position
	var dist := maxf(Vector3(pos.x - w.point.x, 0, pos.z - w.point.z).dot(n), 0.0)
	var probe := pos - n * (dist + 10.0 * u)
	var hit := _ray(Vector3(probe.x, pos.y + LEDGE_PROBE * u, probe.z), Vector3(probe.x, pos.y - 0.05, probe.z))
	if hit.is_empty():
		return {}
	var top: float = hit.position.y
	var ydist := (top - pos.y) / u
	if ydist < LEDGE_MIN or hit.normal.y < LEDGE_FLAT:
		return {}
	if _shape_meta(w.shape, "no_climb") or _shape_meta(_hit_shape(hit), "no_climb"):
		return {}
	# BgCheck_EntityCheckCeiling: nothing overhead up to 20 units above the top.
	if not _ray(pos + Vector3.UP * 1.0, Vector3(pos.x, top + 20.0 * u, pos.z)).is_empty():
		return {}
	# Player_PosVsWallLineTest 5 units above the top: still a wall there means
	# this is a gap in a wall, not a ledge.
	var wy := top + 5.0 * u
	var wall_above := _ray(Vector3(pos.x, wy, pos.z), Vector3(pos.x, wy, pos.z) - n * (dist + 0.3))
	if not wall_above.is_empty() and absf(wall_above.normal.y) < 0.6 and Vector3(wall_above.normal.x, 0, wall_above.normal.z).normalized().dot(n) > 0.7:
		return {}
	# The top has to go on a little way (no perching on rails, posts or fences).
	var deep := pos - n * (dist + 0.55)
	var floor_in := _ray(Vector3(deep.x, top + 0.5, deep.z), Vector3(deep.x, top - 0.3, deep.z))
	if floor_in.is_empty() or absf(floor_in.position.y - top) > 0.3:
		return {}
	# ...and is as wide as he is, side to side: no perching on the end of a
	# thin wall where another wall meets it (a T in a row of cells), and from
	# there walking the wall tops past bars and gates (beta 1.5.1).
	var side := Vector3(-n.z, 0, n.x) * PERCH_HALF_WIDTH
	for s: Vector3 in [side, -side]:
		var sf := _ray(Vector3(deep.x + s.x, top + 0.5, deep.z + s.z), Vector3(deep.x + s.x, top - 0.3, deep.z + s.z))
		if sf.is_empty() or absf(sf.position.y - top) > 0.3:
			return {}
	var type := 4
	if ydist < LEDGE_HOP:
		type = 1
	elif ydist < LEDGE_STEP:
		type = 2
	elif ydist < LEDGE_PULL:
		type = 3
	return {"type": type, "y": top, "ydist": ydist, "n": n, "point": w.point, "a_climb": _shape_meta(w.shape, "climb_with_a")}


## Runs after every move: ledge climbing from the ground (Player_ActionHandler_12),
## grabbing ladders (Player_ActionHandler_5) and catching ledges in the air.
func _update_ledges(delta: float) -> void:
	if is_climbing():
		return   # this frame already started a hang, a ladder or a climb
	var frames := _frames(delta)
	if state == State.AIR:
		_ledge = {}
		_ledge_type = 0
		if _facing_wall(_wall) and speed_oot > 0.0 and not _hop and _no_grab_time <= 0.0 and not is_carrying():
			_try_air_grab()
		return
	var pushing := _facing_wall(_wall) and speed_oot > 0.0 and _stick_mag > 0.0 and input_enabled
	if not (state in [State.IDLE, State.MOVE, State.TURN]) or not is_on_floor() or not pushing:
		_ledge = {}
		_ledge_type = 0
		_ledge_timer = 0.0
		return
	if _shape_meta(_wall.shape, "ladder") and not is_carrying():
		var ledge := _probe_ledge(_wall)
		if ledge.is_empty() or ledge.ydist >= LEDGE_PULL:
			_grab_ladder(_wall)
			return
	_ledge = _probe_ledge(_wall)
	var type: int = _ledge.get("type", 0)
	if type == 0 and _try_step_up(_wall):
		return
	if type == _ledge_type:
		_ledge_timer = minf(_ledge_timer + frames, 100.0)
	else:
		_ledge_type = type
		_ledge_timer = 0.0
	if type == 0 or _ledge.a_climb or (type >= 2 and is_carrying()):
		return
	if type == 1 and _ledge_timer >= 3.0:
		# PLAYER_LEDGE_CLIMB_1: a little hop up onto it.
		var vy: float = _ledge.ydist * 0.08 + 5.5
		speed_oot = 2.5
		move_yaw = facing_yaw
		_jump(vy, &"jump")
	elif type >= 2 and _ledge_timer >= 6.0:
		_start_ledge_climb(_ledge)


## Anything lower than a ledge (under LEDGE_MIN, 18 units) is simply walked
## up, as OoT's floor check lifts Link onto low steps and kerbs: a stepping
## stone, a low plinth, a sill. True when he stepped up.
func _try_step_up(w: Dictionary) -> bool:
	if w.is_empty() or _shape_meta(w.shape, "no_climb"):
		return false
	var n: Vector3 = w.n
	var pos := global_position
	var dist := maxf(Vector3(pos.x - w.point.x, 0, pos.z - w.point.z).dot(n), 0.0)
	var ahead := pos - n * (dist + 0.3)
	var top_ray := _ray(Vector3(ahead.x, pos.y + LEDGE_MIN * oot_unit + 0.05, ahead.z), Vector3(ahead.x, pos.y + 0.04, ahead.z))
	if top_ray.is_empty() or (top_ray.normal as Vector3).y < LEDGE_FLAT:
		return false
	if _shape_meta(_hit_shape(top_ray), "no_climb"):
		return false
	var rise: float = top_ray.position.y - pos.y
	if rise < 0.05 or rise > LEDGE_MIN * oot_unit + 0.02:
		return false
	# Room for him up there (no wall or ceiling in the way).
	var to := Vector3(ahead.x, top_ray.position.y + 0.03, ahead.z)
	if not _ray(Vector3(pos.x, to.y + 1.0, pos.z), to + Vector3.UP * 1.0).is_empty():
		return false
	var old := focus_position()
	global_position = Vector3(pos.x, to.y, pos.z) - n * minf(dist + 0.12, 0.3)
	_start_model_offset(old - focus_position(), 0.1, false)
	return true


## Player_Action_80845668: step up onto a 41-79 unit ledge, or jump at a higher one.
func _start_ledge_climb(ledge: Dictionary) -> void:
	_ledge_type = 0
	_ledge_timer = 0.0
	_clear_z_targeting()
	_end_bow_z()
	facing_yaw = _yaw_of(-ledge.n)
	move_yaw = facing_yaw
	rotation.y = facing_yaw
	_ledge = ledge
	if ledge.type >= 4:
		_climb_kind = Climb.JUMP_GRAB
		_climb_time = jump_grab_windup
		speed_oot = 0.0
		_change_state(State.CLIMB)
		model.play(&"jump_reach", 0.06, 1.0, true)
		return
	_climb_kind = Climb.STEP_LOW if ledge.type == 2 else Climb.STEP_HIGH
	_climb_time = step_low_time if ledge.type == 2 else step_high_time
	_climb_onto(ledge, &"climb_low" if ledge.type == 2 else &"climb_high")


## Moves the body onto the ledge top at once and lets the model catch up.
func _climb_onto(ledge: Dictionary, anim: StringName) -> void:
	var n: Vector3 = ledge.n
	var p: Vector3 = ledge.point
	var target := Vector3(p.x, ledge.y + 0.02, p.z) - n * 0.45
	var old := focus_position()
	global_position = target
	speed_oot = 0.0
	velocity = Vector3.ZERO
	_change_state(State.CLIMB)
	model.play(anim, 0.05, 1.0, true)
	_start_model_offset(old - target, _climb_time, true)
	Sfx.play("climb", -6.0)


func _state_climb(_delta: float) -> void:
	match _climb_kind:
		Climb.JUMP_GRAB:
			if _state_time >= _climb_time:
				# Jump straight up the wall (capped at 111 units) and catch the top.
				var h := minf(_ledge.get("ydist", LEDGE_PULL), LEDGE_PROBE)
				speed_oot = 1.0
				move_yaw = facing_yaw
				_jump(h * 0.072, &"jump_reach")
		_:
			if _state_time >= _climb_time:
				_change_state(State.IDLE)
				model.play(&"idle", 0.15)


## Air grab (Player_Action_8084411C): a ledge between 41 units and the hands'
## reach above the feet, at least 70 units over the floor below.
func _try_air_grab() -> void:
	var ledge := _probe_ledge(_wall)
	if ledge.is_empty() or ledge.type < 2 or ledge.y - global_position.y > hang_reach + 0.05:
		return
	if (global_position.y - _floor_height_below()) / oot_unit + ledge.ydist <= HANG_CLEARANCE:
		return
	_start_hang(ledge, 0.15)


func _floor_height_below() -> float:
	var hit := _ray(global_position + Vector3.UP * 0.1, global_position + Vector3.DOWN * 40.0)
	return -1000.0 if hit.is_empty() else hit.position.y


## func_8083A6AC: walked slowly off an edge; find the face below it and hang
## (or step onto a ladder going down).
func _try_edge_hang() -> bool:
	var back := -_dir(move_yaw)
	var y := _last_floor_y - 0.15
	var from := Vector3(global_position.x, y, global_position.z) - back * 0.1
	var hit := _ray(from, from + back * 0.9)
	if hit.is_empty() or absf(hit.normal.y) > WALL_MAX_NY:
		return false
	var n := Vector3(hit.normal.x, 0, hit.normal.z).normalized()
	var shape := _hit_shape(hit)
	var w := {"n": n, "point": hit.position, "shape": shape}
	if _shape_meta(shape, "ladder"):
		_grab_ladder(w, true)
		return true
	_start_hang({"type": 4, "y": _last_floor_y, "ydist": 0.0, "n": n, "point": hit.position, "a_climb": false}, 0.3)
	return true


## Player_Action_8084BBE4: hands on the edge, body against the wall.
func _start_hang(ledge: Dictionary, ease_time: float) -> void:
	_clear_z_targeting()
	_end_bow_z()
	_ledge = ledge
	var n: Vector3 = ledge.n
	var p: Vector3 = ledge.point
	var old := focus_position()
	var target := Vector3(p.x, ledge.y - hang_reach, p.z) + n * 0.34
	global_position = target
	facing_yaw = _yaw_of(-n)
	move_yaw = facing_yaw
	rotation.y = facing_yaw
	speed_oot = 0.0
	velocity = Vector3.ZERO
	_jumped = false
	_hop = false
	_change_state(State.HANG)
	model.play(&"hang", 0.05, 1.0, true)
	_start_model_offset(old - target, ease_time, false)
	Sfx.play("ledge_grab", -4.0)
	GameManager.rumble(0.3, 0.1)


func _state_hang(_delta: float) -> void:
	speed_oot = 0.0
	if _state_time < hang_settle or not input_enabled:
		return
	# Any firm push of the stick climbs up (controlStickSpinAngles >= 0).
	if _stick_mag >= 55.0:
		_climb_kind = Climb.HANG_UP
		_climb_time = hang_up_time
		_climb_onto(_ledge, &"hang_up")
		return
	if Input.is_action_pressed("interact") or _feet_on_floor():
		_let_go(0.8)


func _feet_on_floor() -> bool:
	return not _ray(global_position + Vector3.UP * 0.05, global_position + Vector3.DOWN * 0.08).is_empty()


## Drops off a ledge or ladder, moving a little away from the wall.
func _let_go(back_speed: float) -> void:
	move_yaw = facing_yaw + PI
	speed_oot = back_speed
	_jumped = true
	_no_grab_time = 0.4
	velocity = Vector3.ZERO
	_change_state(State.AIR)
	model.play(&"fall", 0.1)


## func_8083EC18 for a ladder: snap onto its center line at a rung and face it.
func _grab_ladder(w: Dictionary, from_top := false) -> void:
	var shape := w.shape as CollisionShape3D
	if shape == null or not (shape.shape is BoxShape3D):
		return
	var box := shape.shape as BoxShape3D
	var xf := shape.global_transform
	var n: Vector3 = w.n
	var bottom := xf.origin.y - box.size.y * 0.5
	var top := xf.origin.y + box.size.y * 0.5
	var depth := absf(n.dot(xf.basis.z.normalized())) * box.size.z * 0.5 + absf(n.dot(xf.basis.x.normalized())) * box.size.x * 0.5
	var centre := Vector3(xf.origin.x, 0, xf.origin.z) + n * (depth + 0.34)
	_clear_z_targeting()
	_end_bow_z()
	_ladder = {"n": n, "centre": centre, "bottom": bottom, "top": top}
	var old := focus_position()
	var y := global_position.y
	if from_top:
		y = top - hang_reach
	var rung := RUNG * oot_unit
	# Snap to a rung (never below the ground he is standing on).
	y = bottom + maxf(ceilf((y - bottom) / rung - 0.25), 0.0) * rung
	if not from_top:
		while y < global_position.y - 0.05:
			y += rung
	global_position = Vector3(centre.x, y, centre.z)
	facing_yaw = _yaw_of(-n)
	move_yaw = facing_yaw
	rotation.y = facing_yaw
	speed_oot = 0.0
	velocity = Vector3.ZERO
	_jumped = false
	_ladder_dir = 0
	_change_state(State.LADDER)
	model.play(&"ladder_climb", 0.08, 0.0, true)
	_start_model_offset(old - global_position, 0.3 if from_top else 0.12, false)
	Sfx.play("ladder_step", -6.0)


## Stick up/down on the ladder (camera-independent, like OoT's stick_y), -1..1.
func _ladder_input() -> float:
	if not input_enabled:
		return 0.0
	if debug_use_move_input:
		return clampf(debug_move_input.dot(-_ladder.n), -1.0, 1.0)
	return Input.get_axis("move_back", "move_forward")


## Player_Action_8084BF1C: one rung per step.
func _state_ladder(delta: float) -> void:
	speed_oot = 0.0
	if _ladder_dir != 0:
		_ladder_t += delta
		var k := clampf(_ladder_t / _ladder_len, 0.0, 1.0)
		global_position.y = lerpf(_ladder_from, _ladder_to, k)
		if k >= 1.0:
			_ladder_dir = 0
			model.play(&"ladder_climb", 0.0, 0.0)
		return
	if input_enabled and Input.is_action_just_pressed("interact") and _state_time > 0.2:
		_let_go(0.4)
		return
	var stick := _ladder_input()
	if absf(stick) < 0.2:
		model.play(&"ladder_climb", 0.0, 0.0)
		return
	var u := oot_unit
	# Animation rate |stick_y| * 0.05 (1 to 3.35); a rung takes 20 frames at 1x.
	var rate := clampf(absf(stick) * 60.0 * 0.05, 1.0, 3.35)
	_ladder_len = 20.0 / (rate * OOT_RATE) / OOT_FPS
	if stick > 0.0:
		# A floor 70 units up and 26 in front: climb over the top.
		var ln: Vector3 = _ladder.n
		var probe := global_position + Vector3.UP * 70.0 * u - ln * 26.0 * u
		var hit := _ray(probe, probe + Vector3.DOWN * 60.0 * u)
		if not hit.is_empty() and hit.normal.y > LEDGE_FLAT and global_position.y + 0.3 < hit.position.y:
			_climb_kind = Climb.LADDER_TOP
			_climb_time = hang_up_time
			_climb_onto({"n": _ladder.n, "point": global_position - _ladder.n * 0.34, "y": hit.position.y}, &"hang_up")
			return
		_ladder_dir = 1
	else:
		var floor_y := _floor_height_below()
		if global_position.y - floor_y < RUNG * u:
			# Step off the bottom (func_8083F070 with the climb-down end animation).
			var old := focus_position()
			global_position.y = floor_y
			_change_state(State.IDLE)
			model.play(&"idle", 0.2)
			_start_model_offset(old - global_position, 0.25, false)
			return
		_ladder_dir = -1
	_ladder_from = global_position.y
	_ladder_to = global_position.y + _ladder_dir * RUNG * u
	_ladder_t = 0.0
	# Two rungs per animation cycle (climb_upL then climb_upR).
	var cycle: float = model.anim.get_animation(&"ladder_climb").length if model.anim.has_animation(&"ladder_climb") else 1.0
	model.play(&"ladder_climb", 0.0, _ladder_dir * cycle * 0.5 / _ladder_len)
	Sfx.play("ladder_step", -8.0)


# --- First-person view, bow and talking -----------------------------------------

## func_8083B8F4: C-Up looks around in first person when standing on the ground.
func _try_look() -> bool:
	if not is_on_floor() or lock_target or is_carrying():
		Sfx.play("error", -6.0)
		return false
	_clear_z_targeting()
	look_yaw = facing_yaw
	look_pitch = 0.0
	_look_by_mouse = false
	GameManager.take_mouse_motion()
	_change_state(State.LOOK)
	model.play(&"idle", 0.1)
	Sfx.play("camera_in", -6.0)
	return true


## An item button: the bow goes to first-person aiming, or stays in the
## third-person view while Z-targeting.
func _use_item(button: String) -> bool:
	var item := Progress.item_on(button)
	if item == "":
		Sfx.play("error", -6.0)
		return false
	if item == "boomerang":
		return _ready_boomerang(button)
	if item == "sugar_cube":
		return _call_horse()
	if item == "trade_item":
		# Held up for a look: a reminder of where it goes next.
		if is_on_floor() and not Dialogue.active:
			Dialogue.start([TradeLines.hint()], null)
		return false
	if item == "hookshot":
		return _ready_hookshot(button)
	if item == "bombs":
		return _pull_bomb()
	if item == "bloom_rod":
		return _ready_bloom_rod(button)
	if item.begins_with("bottle_"):
		return _use_bottle(int(item.trim_prefix("bottle_")))
	if PlayerItems.handles(item):
		return items.use(item, button)
	if item != "bow" and PlayerItems.arrow_kind(item) == "":
		return false
	if Progress.arrows <= 0 or not is_on_floor():
		Sfx.play("error", -6.0)
		return false
	# Sun and Frost Arrows draw the bow too, and need magic to loose.
	arrow_kind = PlayerItems.arrow_kind(item)
	if arrow_kind != "" and Progress.magic < Progress.magic_cost(item):
		Sfx.play("error", -6.0)
		return false
	_aim_button = button
	if is_z_targeting():
		if hook_z:
			_end_hook_z()
		if not bow_z:
			bow_z = true
			model.set_bow_out(true)
			Sfx.play("bow_draw", -6.0)
		_bow_ready()
		return false   # keeps moving; the bow is an upper-body action
	if not (state in [State.LOOK, State.AIM]):
		look_yaw = facing_yaw
		look_pitch = 0.0
		_look_by_mouse = false
	GameManager.take_mouse_motion()
	aim_item = "bow"
	_change_state(State.AIM)
	model.set_bow_out(true)
	_bow_ready()
	Sfx.play("bow_draw", -6.0)
	return true


## A bottle's button (OoT's bottles, Player_UseItem with a bottle):
## - empty: a swing that catches a fairy in front of the hero;
## - a fairy: let her out, and she heals him (Fairy.released);
## - milk (two drinks, 5 hearts each) or a red potion (every heart): drunk
##   on the spot;
## - a fish: let out (BottledFish), it swims away if it lands in water.
func _use_bottle(i: int) -> bool:
	var content := Progress.bottle(i)
	if content == "" or not is_on_floor() or is_carrying() or state in [State.TALK, State.DEAD, State.SWIM, State.AIM]:
		Sfx.play("error", -6.0)
		return false
	match content:
		"empty":
			_swing_bottle(i)
		"fairy":
			Progress.set_bottle(i, "empty")
			var f := Fairy.new()
			f.released = true
			get_parent().add_child(f)
			f.global_position = global_position + Vector3.UP * 1.3 + forward() * 0.4
			Sfx.play("bottle_swing", -4.0, 0.05, 1.2)
		"fish":
			# Let out: it leaps ahead, and swims off if it lands in water.
			Progress.set_bottle(i, "empty")
			model.play(&"throw_carry", 0.05, 1.2, true)
			var fish := BottledFish.new()
			get_parent().add_child(fish)
			fish.global_position = global_position + Vector3.UP * 1.2 + forward() * 0.4
			fish.leap(forward())
			Sfx.play("bottle_swing", -4.0, 0.05, 0.9)
		"milk", "half_milk", "red_potion":
			var heal_by := health.max_health if content == "red_potion" else 10
			if health.health >= health.max_health:
				Sfx.play("error", -6.0)
				return false
			Progress.set_bottle(i, "half_milk" if content == "milk" else "empty")
			model.play(&"item_get", 0.1, 1.0, true)
			speed_oot = 0.0
			Sfx.play("bottle_pour", -4.0, 0.05, 0.8)
			health.heal(heal_by)
			get_tree().create_timer(0.5).timeout.connect(func() -> void: Sfx.play("heart", -4.0))
	return false


## The empty bottle swung through the air: a fairy in front of the hero
## (within reach, ahead of him) goes into it.
func _swing_bottle(i: int) -> void:
	model.play(&"throw_carry", 0.05, 1.4, true)
	Sfx.play("bottle_swing", -4.0)
	var reach := global_position + Vector3.UP * 1.0 + forward() * 0.6
	for n in get_tree().get_nodes_in_group("fairies"):
		var f := n as Fairy
		if f == null or f.released:
			continue
		var d := f.global_position - reach
		if d.length() < 1.6:
			f.catch()
			Progress.set_bottle(i, "fairy")
			Sfx.play("bottle_catch", -2.0, 0.0)
			Dialogue.start(["You caught a *Fairy* in a bottle!\nUse it to be healed, or keep it: if you fall in battle, she will bring you back!"])
			return


## The Bloom Rod's button: aimed like the Hookshot (CAM_MODE_AIM_ADULT);
## letting go flings a seed along the line of sight (BloomSeed).
func _ready_bloom_rod(button: String) -> bool:
	if not is_on_floor() or is_carrying() or state in [State.TALK, State.DEAD, State.LIFT, State.THROW]:
		Sfx.play("error", -6.0)
		return false
	_aim_button = button
	if not (state in [State.LOOK, State.AIM]):
		look_yaw = facing_yaw
		look_pitch = 0.0
		_look_by_mouse = false
	GameManager.take_mouse_motion()
	aim_item = "bloom_rod"
	_change_state(State.AIM)
	_show_bloom_rod(true)
	_bow_ready()
	Sfx.play("lift_plant", -8.0, 0.05, 1.3)
	return true


## Ready, then letting go of the button flings the seed; press again to aim
## the next one.
func _update_bloom_rod(delta: float) -> void:
	_bow_time += delta
	match bow_phase:
		Bow.READY:
			if _bow_time >= bow_ready_time:
				bow_phase = Bow.DRAWN
		Bow.DRAWN:
			if not _bow_held():
				_fire_seed()
				bow_phase = Bow.SHOT
				_bow_time = 0.0
		Bow.SHOT:
			if _bow_pressed() and _bow_time > 0.25:
				_bow_ready()


func _fire_seed() -> void:
	var cam := camera_rig.camera if camera_rig else null
	var dir := -cam.global_basis.z if cam else forward()
	var seed := BloomSeed.new()
	var parent := World.area_node if is_instance_valid(World.area_node) else get_parent()
	parent.add_child(seed)
	seed.launch(self, aim_origin() + dir * 0.5, dir)
	Sfx.play("seed_shoot", -4.0, 0.06)
	GameManager.rumble(0.2, 0.08)


var _bloom_mesh: MeshInstance3D = null


func _show_bloom_rod(on: bool) -> void:
	if _bloom_mesh == null and on:
		var hand := model.get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
		if hand == null:
			return
		_bloom_mesh = MeshInstance3D.new()
		_bloom_mesh.name = "HandBloomRod"
		_bloom_mesh.mesh = load("res://assets/models/bloom_rod_mesh.tres")
		_bloom_mesh.position = Vector3(0, -0.06, 0)
		hand.add_child(_bloom_mesh)
	if _bloom_mesh:
		_bloom_mesh.visible = on


## The bomb button (Player_UpdateUpperBody's explosive handling): a lit bomb
## comes out of the bag straight into his hands, held overhead like a pot.
## Three may be out at once, as in OoT.
func _pull_bomb() -> bool:
	if is_carrying() or not is_on_floor() or Progress.bombs <= 0 or is_climbing() \
			or not (state in [State.IDLE, State.TURN, State.MOVE]) \
			or get_tree().get_nodes_in_group("bombs").size() >= 3:
		Sfx.play("error", -6.0)
		return false
	Progress.use_bomb()
	_end_bow_z()
	_cancel_boomerang()
	_set_sword_drawn(false)
	var b := Bomb.make()
	b.thrower = self
	var parent := World.area_node if is_instance_valid(World.area_node) else get_parent()
	parent.add_child(b)
	held = b
	b.global_transform = _hold_transform()
	model.set_shield_on_back(true)
	_set_upper("carry")
	model.upper_weight = 1.0
	Sfx.play("lift_pot", -6.0, 0.05, 1.3)
	return false


## Puts the bomb in his hands down in front of his feet.
func _set_down_bomb() -> void:
	var b := held as Bomb
	held = null
	model.set_shield_on_back(false)
	if is_instance_valid(b):
		b.set_down(global_position + forward() * 0.6 + Vector3.UP * 0.05)
		Sfx.play("lift_pot", -8.0, 0.05, 0.9)


## The Hookshot's button: first-person aim (CAM_MODE_AIM_ADULT, as the bow).
func _ready_hookshot(button: String) -> bool:
	if is_instance_valid(hook) or not is_on_floor() or state in [State.TALK, State.DEAD, State.LIFT, State.THROW]:
		Sfx.play("error", -6.0)
		return false
	_aim_button = button
	# Z-targeting: readied on the upper body, aimed by the lock-on, and he keeps
	# moving (as with the bow); the view stays where it is.
	if is_z_targeting():
		if bow_z:
			_end_bow_z()
		if boom_z:
			_cancel_boomerang()
		if not hook_z:
			hook_z = true
			_show_hookshot(true)
			Sfx.play("bow_draw", -8.0, 0.05, 1.4)
		_bow_ready()
		return false
	if not (state in [State.LOOK, State.AIM]):
		look_yaw = facing_yaw
		look_pitch = 0.0
		_look_by_mouse = false
	GameManager.take_mouse_motion()
	aim_item = "hookshot"
	_change_state(State.AIM)
	_show_hookshot(true)
	_bow_ready()
	Sfx.play("bow_draw", -8.0, 0.05, 1.4)
	return true


## Aiming the Hookshot: ready, then letting go of its button fires the chain;
## while it is out he waits, and pressing again after it is back fires again.
func _update_hookshot(delta: float) -> void:
	_bow_time += delta
	if is_instance_valid(hook):
		return
	match bow_phase:
		Bow.READY:
			if _bow_time >= bow_ready_time:
				bow_phase = Bow.DRAWN
		Bow.DRAWN:
			if not _bow_held():
				_fire_hookshot()
				bow_phase = Bow.SHOT
		Bow.SHOT:
			if _bow_pressed():
				_bow_ready()


func _fire_hookshot() -> void:
	var cam := camera_rig.camera if camera_rig else null
	var from := aim_origin()
	var dir := -cam.global_basis.z if cam else forward()
	if hook_z:
		# From the hand, at the lock-on target's middle (or straight ahead).
		from = global_position + Vector3.UP * 1.3
		dir = forward()
		if lock_target and is_instance_valid(lock_target):
			dir = (lock_target.aim_point() - from).normalized()
	hook = Hookshot.new()
	var parent := World.area_node if is_instance_valid(World.area_node) else get_parent()
	parent.add_child(hook)
	hook.launch(self, from + dir * 0.4, dir)
	GameManager.rumble(0.3, 0.1)


## The Hookshot readied while Z-targeting: the same ready / release-to-fire /
## press-again cycle as in first person. It ends with Z, or when he can no
## longer hold it; the flight along the chain keeps it out.
func _update_hook_z(delta: float) -> void:
	if state == State.HOOKFLY:
		return
	if not is_z_targeting() or not (state in [State.IDLE, State.TURN, State.MOVE, State.LAND]):
		_end_hook_z()
		return
	_update_hookshot(delta)


func _end_hook_z() -> void:
	if not hook_z:
		return
	hook_z = false
	bow_phase = Bow.NONE
	if state != State.HOOKFLY:
		_show_hookshot(false)


func _show_hookshot(on: bool) -> void:
	if _hook_mesh == null and on:
		var hand := model.get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
		if hand == null:
			return
		_hook_mesh = MeshInstance3D.new()
		_hook_mesh.name = "HandHookshot"
		_hook_mesh.mesh = load("res://assets/models/hookshot_mesh.tres")
		_hook_mesh.position = Vector3(0, -0.08, 0)
		hand.add_child(_hook_mesh)
	if _hook_mesh:
		_hook_mesh.visible = on


## Where the chain leaves his hand.
func hookshot_origin() -> Vector3:
	var hand := model.get_node_or_null("Hips/Torso/ShoulderR/ElbowR/HandR") as Node3D
	if hand and state != State.AIM:
		return hand.global_position
	return aim_origin() + forward() * 0.3 + Vector3.DOWN * 0.25


## The chain bit into a target (ArmsHook_PullPlayer): fly to it.
func hook_pull(h: Hookshot) -> void:
	hook = h
	if is_first_person():
		aim_item = ""
		bow_phase = Bow.NONE
	_change_state(State.HOOKFLY)
	model.play(&"jump_reach", 0.05)
	if camera_rig:
		camera_rig.snap_behind_target()


## Player_Action_HookshotFly: 30 units a frame along the chain; within 50
## units of the tip he lets go, faces the target and drops (catching the ledge
## above it if there is one).
func _state_hookfly(delta: float) -> void:
	if not is_instance_valid(hook):
		_change_state(State.AIR)
		return
	var stop := hook.anchor + hook.anchor_normal * 0.45 - Vector3.UP * 1.3
	var to := stop - global_position
	var step := Hookshot.mps(Hookshot.PULL_SPEED) * delta
	if to.length() > 50.0 * oot_unit and to.length() > step:
		global_position += to.normalized() * step
		var flat := Vector3(-hook.anchor_normal.x, 0, -hook.anchor_normal.z)
		if flat.length() > 0.1:
			facing_yaw = _yaw_of(flat)
			rotation.y = facing_yaw
		return
	global_position = stop
	_show_hookshot(false)
	var flat_n := Vector3(-hook.anchor_normal.x, 0, -hook.anchor_normal.z)
	if flat_n.length() > 0.1:
		face_direction(flat_n)
	var n := Vector3(hook.anchor_normal.x, 0, hook.anchor_normal.z).normalized()
	var anchor := hook.anchor
	hook.release()
	hook = null
	velocity = Vector3.ZERO
	# A ledge just above the target (a gallery's rim): he catches hold of it.
	if n.length() > 0.5:
		var ledge := _probe_ledge({"n": n, "point": anchor, "shape": null})
		if not ledge.is_empty() and ledge.y - global_position.y <= hang_reach + 0.35:
			_start_hang(ledge, 0.15)
			Sfx.play("hookshot_stick", -8.0, 0.05, 0.8)
			return
	# Otherwise he drops off the target, leaning into the wall.
	speed_oot = 1.0
	move_yaw = facing_yaw
	_jumped = true
	_no_grab_time = 0.0
	_change_state(State.AIR)
	Sfx.play("hookshot_stick", -8.0, 0.05, 0.8)


## The Sugar Cube: out on the open fields, Biscuit comes running (the one
## already here, or she arrives from out of sight behind the hero).
func _call_horse() -> bool:
	if not Progress.flag("horse_owned") or not WorldData.horse_allowed(World.area_id) or not is_on_floor():
		Sfx.play("error", -6.0)
		return false
	var h: Horse = null
	for n in get_tree().get_nodes_in_group("horses"):
		if is_instance_valid(n) and (n as Horse).rider == null:
			h = n
	if h == null:
		var back := global_position - forward() * 22.0
		var hit := _ray(back + Vector3.UP * 30.0, back + Vector3.DOWN * 30.0)
		if not hit.is_empty():
			back.y = hit.position.y + 0.1
		h = Horse.spawn(World.area_node, back, facing_yaw)
	h.call_to(global_position)
	Sfx.play("item_pop", -6.0)
	return false


## The boomerang's item button (func_80834EB8): only one can be out at a time.
## On the ground without Z-targeting, holding the button aims it
## (CAM_MODE_AIM_BOOMERANG); Z-targeting, it is readied on the upper body and
## thrown at the target on release. In the air it is thrown straight away.
func _ready_boomerang(button: String) -> bool:
	if is_instance_valid(boomerang) or _boom_ready >= 0.0 or is_climbing() \
			or state in [State.TALK, State.DEAD, State.LIFT, State.THROW]:
		Sfx.play("error", -6.0)
		return false
	_aim_button = button
	if not is_on_floor():
		_throw_boomerang(facing_yaw, 0.0)
		return false
	_boom_ready = 0.0
	_boom_throw = -1.0
	model.set_boomerang_in_hand(true)
	if is_z_targeting():
		_end_bow_z()
		boom_z = true
		return false   # keeps moving; it is an upper-body action
	if not (state in [State.LOOK, State.AIM]):
		look_yaw = facing_yaw
		look_pitch = 0.0
		_look_by_mouse = false
	GameManager.take_mouse_motion()
	aim_item = "boomerang"
	_change_state(State.AIM)
	Sfx.play("camera_in", -8.0)
	return true


func _boom_held() -> bool:
	return debug_bow_hold or (input_enabled and Input.is_action_pressed(_aim_button))


## func_808358F0 / func_808359FC: once readied, letting go of the button swings
## (boom_throwR) and the boomerang leaves the hand on frame 6. Returns true once
## it has been thrown.
func _update_boomerang_hold(delta: float, yaw: float, pitch: float) -> bool:
	_boom_ready += delta
	if _boom_throw < 0.0:
		if _boom_ready >= boomerang_ready_time and not _boom_held():
			_boom_throw = 0.0
			_throw_time = THROW_TIME
		return false
	_boom_throw += delta
	if _boom_throw >= boomerang_release_time:
		_throw_boomerang(yaw, pitch)
		return true
	return false


## EnBoom from 10 units in front and 30 up, along `yaw` and `pitch`, or curving
## in on the Z-target.
func _throw_boomerang(yaw: float, pitch: float) -> void:
	_boom_ready = -1.0
	_boom_throw = -1.0
	model.set_boomerang_in_hand(false)
	if is_instance_valid(boomerang):
		return
	var b := Boomerang.new()
	var parent := World.area_node if is_instance_valid(World.area_node) else get_parent()
	parent.add_child(b)
	boomerang = b
	var from := Vector3.INF
	if lock_target:
		facing_yaw = _yaw_of(lock_target.global_position - global_position)
		yaw = facing_yaw
		pitch = 0.0
	elif state == State.AIM:
		# With the reticle on something within reach (a wall, the floor, a
		# creature, an item), it leaves his hand straight for that point, so it
		# goes where he aims. Otherwise it skims out along the aim from the
		# hand, as in OoT (low enough to sweep up items on the ground).
		var hit := _aim_ray(yaw, pitch, Boomerang.RANGE)
		if not hit.is_empty():
			from = global_position + Vector3(-sin(yaw), 0, -cos(yaw)) * 0.3 + Vector3.UP * 0.9
			var to: Vector3 = hit.position - from
			if to.length() > 0.5:
				yaw = atan2(-to.x, -to.z)
				pitch = atan2(to.y, Vector2(to.x, to.z).length())
	b.throw(self, yaw, pitch, lock_target, from)
	_throw_time = THROW_TIME


## The unit vector along a yaw and pitch (the view's -Z).
func _dir_of(yaw: float, pitch: float) -> Vector3:
	return Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))


## Whether the aim (the reticle's line) lies on something the arrow or the
## boomerang can hit within its reach: a creature, a switch, a pot, grass or
## an item. The HUD's reticle lights up over one.
func _update_aim_target() -> void:
	aim_on_target = false
	if not is_inside_tree():
		return
	var boom := aim_item == "boomerang"
	var hooking := aim_item == "hookshot"
	if aim_item == "bloom_rod":
		# The dot turns green where a seed would take root.
		var bh := _aim_ray(look_yaw, look_pitch, BloomSeed.RANGE)
		aim_on_target = not bh.is_empty() and (bh.get("normal", Vector3.ZERO) as Vector3).y > 0.6
		return
	var reach := Boomerang.RANGE if boom else (Hookshot.mps(Hookshot.SPEED) / Hookshot.OOT_FPS * Hookshot.LIFE if hooking else aim_reach_bow)
	var hit := _aim_ray(look_yaw, look_pitch, reach)
	if hit.is_empty():
		return
	if hooking:
		# The Hookshot's dot turns green on a target, a creature or a pickup.
		var shape := Hookshot._hit_shape(hit)
		var hurt_h := hit.collider as Hurtbox
		aim_on_target = (shape != null and shape.get_meta("hookable", false)) or hurt_h != null
		return
	var hurt := hit.collider as Hurtbox
	var who: Object = hurt.receiver if hurt else hit.collider
	if who == null:
		return
	if who is Enemy:
		aim_on_target = not (who as Enemy).is_dead()
	elif boom:
		aim_on_target = who is Collectible or who.has_method("boomerang_hit")
	else:
		aim_on_target = who.has_method("arrow_hit")


## What the reticle's line (from the head along `yaw` and `pitch`) meets
## within `reach`: the world or a hurtbox other than his own ({} = nothing).
func _aim_ray(yaw: float, pitch: float, reach: float) -> Dictionary:
	if not is_inside_tree():
		return {}
	var from := aim_origin()
	var q := PhysicsRayQueryParameters3D.create(from, from + _dir_of(yaw, pitch) * reach, Boomerang.HIT_MASK)
	q.collide_with_areas = true
	var ex: Array[RID] = [get_rid()]
	var hb := get_node_or_null("Hurtbox") as Area3D
	if hb:
		ex.append(hb.get_rid())
	q.exclude = ex
	return get_world_3d().direct_space_state.intersect_ray(q)


## The Z-target boomerang: readied on the upper body while he moves.
func _update_boom_z(delta: float) -> void:
	if not is_z_targeting() or not (state in [State.IDLE, State.TURN, State.MOVE, State.LAND]):
		_cancel_boomerang()
		return
	if _update_boomerang_hold(delta, facing_yaw, 0.0):
		boom_z = false


func _cancel_boomerang() -> void:
	boom_z = false
	_boom_ready = -1.0
	_boom_throw = -1.0
	model.set_boomerang_in_hand(false)


# --- Lifting and throwing ---------------------------------------------------------

## The object A would lift: in its offered range (Actor_OfferGetItem) and the
## most squarely in front of the hero, within `lift_face_angle`.
func lift_candidate() -> Node3D:
	if is_carrying() or not (state in [State.IDLE, State.TURN, State.MOVE]):
		return null
	var best: Node3D = null
	var best_angle := lift_face_angle * BINANG
	for n in get_tree().get_nodes_in_group("liftables"):
		var node := n as Node3D
		if node == null or not node.is_inside_tree() or not node.can_lift():
			continue
		var r: Vector2 = node.lift_range()
		var to := node.global_position - global_position
		if absf(to.y) >= r.y:
			continue
		to.y = 0.0
		if to.length() >= r.x:
			continue
		var angle := absf(angle_difference(facing_yaw, _yaw_of(to))) if to.length() > 0.05 else 0.0
		if angle < best_angle:
			best = node
			best_angle = angle
	return best


## func_8083A0F4 / Player_Action_80846050: put the sword away, turn to the
## object and lift it with the carryB animation.
func _start_lift(thing: Node3D) -> void:
	_end_bow_z()
	_cancel_boomerang()
	_set_sword_drawn(false)
	face_direction(thing.global_position - global_position)
	_lift_thing = thing
	held = null
	speed_oot = 0.0
	_change_state(State.LIFT)
	model.play(&"lift", 0.05, 1.0, true)
	model.set_shield_on_back(true)


func _state_lift(delta: float) -> void:
	speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
	if held == null and _state_time >= lift_grab_time:
		# Frame 4: the object is taken in hand (heldActor, its parent set).
		if is_instance_valid(_lift_thing) and _lift_thing.can_lift():
			held = _lift_thing.lift(self)
			_lift_from = held.global_transform
		_lift_thing = null
		if held == null:
			model.set_shield_on_back(false)
			_change_state(State.IDLE)
			return
	if _state_time >= lift_time:
		# The lift ends in the carry pose, which the upper body now holds.
		_change_state(State.IDLE)
		_set_upper("carry")
		model.upper_weight = 1.0
		model.play(&"idle", 0.1)


## Where a carried object rests: on his palms (OoT places heldActor from the
## hands each frame). The model's palms lag one frame, which does not show.
func _hold_transform() -> Transform3D:
	var palms := model.palms_position()
	if palms == Vector3.ZERO:
		palms = global_position + Vector3.UP * 1.9
	return Transform3D(Basis(Vector3.UP, facing_yaw), palms + Vector3.UP * held.rest_offset())


## Keeps the carried object in his hands. During the lift it is eased from the
## ground into them over the first frames after the grab.
func _update_held() -> void:
	if held != null and not is_instance_valid(held):
		held = null
		model.set_shield_on_back(false)
	if held == null or held.phase != Throwable.Phase.HELD:
		return
	if state == State.LIFT:
		var k := smoothstep(0.0, 1.0, clampf((_state_time - lift_grab_time) / 0.12, 0.0, 1.0))
		var to := _hold_transform()
		held.global_transform = Transform3D(_lift_from.basis.slerp(to.basis, k), _lift_from.origin.lerp(to.origin, k))
	else:
		held.global_transform = _hold_transform()


## func_8083EA94: the throw animation.
func _start_carry_throw() -> void:
	_thrown = false
	_change_state(State.THROW)
	model.play(&"throw_carry", 0.04, 1.0, true)


## Player_Action_80846578.
func _state_throw(delta: float) -> void:
	speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
	if lock_target:
		_face_toward(lock_target.global_position, target_face_step, delta)
	move_yaw = facing_yaw
	if not _thrown and _state_time >= carry_throw_release:
		_thrown = true
		if is_instance_valid(held):
			held.release(facing_yaw, speed_oot + carry_throw_speed, carry_throw_vy)
			Sfx.play("throw", -4.0)
		held = null
	if _state_time >= carry_throw_time or (_state_time >= carry_throw_early and _stick_speed(true) > 0.0):
		model.set_shield_on_back(false)
		_change_state(State.MOVE if _stick_speed(true) > 0.0 else State.IDLE)


## A blow or a fall: the carried object slips from his hands and breaks.
func _drop_held() -> void:
	_lift_thing = null
	if is_instance_valid(held) and held.phase == Throwable.Phase.HELD:
		held.drop()
	held = null
	model.set_shield_on_back(false)


func _bow_ready() -> void:
	bow_phase = Bow.READY
	_bow_time = 0.0


func _bow_held() -> bool:
	return debug_bow_hold or (input_enabled and (Input.is_action_pressed(_aim_button) or Input.is_action_pressed("aim_fire")))


func _bow_pressed() -> bool:
	return input_enabled and (Input.is_action_just_pressed(_aim_button) or Input.is_action_just_pressed("aim_fire"))


## func_808351D4 / func_808353D8: ready, hold, release to shoot, press for the next.
func _update_bow(delta: float, first_person: bool) -> void:
	_bow_time += delta
	match bow_phase:
		Bow.READY:
			if _bow_time >= bow_ready_time:
				bow_phase = Bow.DRAWN
				_bow_time = 0.0
		Bow.DRAWN:
			if not _bow_held():
				_fire_arrow(first_person)
				bow_phase = Bow.SHOT
				_bow_time = 0.0
		Bow.SHOT:
			if _bow_pressed():
				if Progress.arrows > 0:
					_bow_ready()
				else:
					Sfx.play("error", -6.0)


func _fire_arrow(first_person: bool) -> void:
	if Progress.arrows <= 0:
		Sfx.play("bow_flick", -4.0)
		return
	# A magic arrow takes its magic as it flies; with too little left the
	# bow looses a plain arrow (OoT drops back to normal arrows).
	var kind := arrow_kind
	if kind != "" and not Progress.use_magic(Progress.magic_cost(kind + "_arrows")):
		kind = ""
		Sfx.play("error", -8.0)
	Progress.use_arrow()
	var from: Vector3
	var dir: Vector3
	var cam := camera_rig.camera if camera_rig else null
	if first_person and cam:
		dir = -cam.global_basis.z
		from = (aim_origin() if aim_camera_back() > 0.0 else cam.global_position) + dir * 0.3
	else:
		from = global_position + Vector3.UP * 1.4 + forward() * 0.45
		if lock_target and is_instance_valid(lock_target):
			dir = lock_target.aim_point() - from
		else:
			dir = forward()
	var arrow := Arrow.new()
	arrow.kind = kind
	var parent := World.area_node if is_instance_valid(World.area_node) else get_parent()
	parent.add_child(arrow)
	arrow.launch(from, dir, self)
	Sfx.play("arrow_shoot", -2.0)
	model.aim_kick = 1.0
	GameManager.rumble(0.4, 0.08)
	arrow_fired.emit(arrow)


func _update_bow_z(delta: float) -> void:
	# The Z-target bow ends with Z (or when the hero can no longer hold it).
	if not is_z_targeting() or not (state in [State.IDLE, State.TURN, State.MOVE, State.LAND]):
		_end_bow_z()
		return
	_update_bow(delta, false)


func _end_bow_z() -> void:
	_end_hook_z()
	if not bow_z:
		return
	bow_z = false
	bow_phase = Bow.NONE
	model.set_bow_out(false)


## func_8084ABD8: turn and tilt the view. Aiming uses OoT's slower curved rate.
func _update_look(delta: float, aiming: bool) -> void:
	var f := _frames(delta)
	var stick := debug_look_input
	if stick == Vector2.ZERO and input_enabled:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back") \
			+ Input.get_vector("look_left", "look_right", "look_up", "look_down")
		stick = Vector2(v.x, -v.y).limit_length(1.0)
	var sx := stick.x * 60.0
	var sy := stick.y * 60.0
	var inv := -1.0 if GameManager.invert_look else 1.0
	if aiming:
		var limit := 14000.0 * BINANG
		look_pitch += signf(sy) * (1.0 - cos(absf(sy) * 200.0 * BINANG)) * 1500.0 * BINANG * f * inv
		look_yaw -= signf(sx) * (1.0 - cos(absf(sx) * 200.0 * BINANG)) * 1500.0 * BINANG * f
		look_pitch = clampf(look_pitch, -limit, limit)
	else:
		if sy != 0.0 or not _look_by_mouse:
			if sy != 0.0:
				_look_by_mouse = false
			# Math_SmoothStepToS(focus.rot.x, stick_y * 240, 14, 4000, 30).
			var target := sy * 240.0 * BINANG * inv
			look_pitch += (target - look_pitch) * (1.0 - pow(1.0 - 1.0 / 14.0, f))
		look_yaw += clampf(sx * -16.0, -3000.0, 3000.0) * BINANG * f
	var m := GameManager.take_mouse_motion() if input_enabled else Vector2.ZERO
	if m != Vector2.ZERO:
		_look_by_mouse = true
		look_yaw -= m.x * GameManager.mouse_sensitivity
		look_pitch -= m.y * GameManager.mouse_sensitivity * inv
	look_pitch = clampf(look_pitch, -14400.0 * BINANG, 14400.0 * BINANG)
	facing_yaw = look_yaw
	move_yaw = look_yaw


## Player_Action_8084B1D8 in plain first-person view.
func _state_look(delta: float) -> void:
	speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
	_update_look(delta, false)
	model.play(&"idle", 0.15)
	if not input_enabled:
		return
	for b in ["item_x", "item_y"]:
		if Input.is_action_just_pressed(b) and _use_item(b):
			return
	if Input.is_action_just_pressed("first_person") or Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("shield") \
			or Input.is_action_just_pressed("target") or not is_on_floor():
		_leave_first_person()


## Aiming the bow in first person (CAM_MODE_AIM_ADULT), or the boomerang from
## behind the head (CAM_MODE_AIM_BOOMERANG).
func _state_aim(delta: float) -> void:
	speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
	_update_look(delta, true)
	_update_aim_target()
	model.play(&"idle", 0.15)
	if aim_item == "boomerang":
		if _update_boomerang_hold(delta, look_yaw, look_pitch):
			_leave_first_person()
			return
	elif aim_item == "hookshot":
		_update_hookshot(delta)
		if is_instance_valid(hook):
			return
	elif aim_item == "bloom_rod":
		_update_bloom_rod(delta)
	else:
		_update_bow(delta, true)
	if not input_enabled:
		return
	# Player_UpperAction_ChangeHeldItem: the other item button swaps in place.
	for b in ["item_x", "item_y"]:
		if Input.is_action_just_pressed(b) and b != _aim_button:
			_swap_aim_item(b)
			return
	var b_pressed := Input.is_action_just_pressed("attack") and not Input.is_action_just_pressed("aim_fire")
	if b_pressed or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("shield") \
			or Input.is_action_just_pressed("first_person") or Input.is_action_just_pressed("target") \
			or not is_on_floor():
		_leave_first_person()


## Player_UpperAction_ChangeHeldItem while aiming: the held item goes away
## and the new one comes up in the same view, aim and all (in OoT, holding the
## bow, the Hookshot's button brings the Hookshot up without the camera going
## back). An item that is not aimed (a bomb, a bottle...) leaves first person
## and is used as usual.
func _swap_aim_item(button: String) -> void:
	var item := Progress.item_on(button)
	if not (item in AIM_ITEMS):
		_leave_first_person()
		_use_item(button)
		return
	_put_away_aim_item()
	# The old item goes down and the new one comes up (the arms drop and rise
	# again over the upper-body blend).
	model.upper_weight = 0.0
	if not _use_item(button):
		# Out of arrows or magic: he stays in first person, empty-handed.
		aim_item = ""
		_change_state(State.LOOK)


## Puts away whatever is aimed (State.AIM's item).
func _put_away_aim_item() -> void:
	bow_phase = Bow.NONE
	model.set_bow_out(false)
	if aim_item == "boomerang":
		_cancel_boomerang()
	if is_instance_valid(hook):
		hook.release()
		hook = null
	_show_hookshot(false)
	_show_bloom_rod(false)
	aim_item = ""


func _leave_first_person() -> void:
	# B (or A) only returns; it must not also swing the sword afterward.
	combat.clear_buffer()
	_put_away_aim_item()
	items.set_lens(false)
	_change_state(State.IDLE)
	Sfx.play("camera_out", -6.0)
	if camera_rig:
		camera_rig.snap_behind_target()


## Starts a conversation: the hero stops and turns to the speaker.
func begin_talk(partner: Node3D) -> void:
	if is_riding():
		dismount()
	talk_partner = partner
	_clear_z_targeting()
	_end_bow_z()
	if is_first_person():
		_leave_first_person()
	_change_state(State.TALK)


## Holds a new treasure overhead (OoT's get-item pose), turned toward the camera.
func begin_item_get() -> void:
	if is_riding():
		dismount()
	talk_partner = null
	_clear_z_targeting()
	_end_bow_z()
	if is_first_person():
		_leave_first_person()
	_change_state(State.TALK)
	item_get = true
	speed_oot = 0.0
	_set_sword_drawn(false)
	if camera_rig:
		face_direction(camera_rig.camera.global_position - global_position)
	model.play(&"item_get", 0.08, 1.0, true)


## Where falling into a pit returns him: OoT keeps the point where he entered
## the room (RESPAWN_MODE_DOWN).
func set_respawn(t: Transform3D) -> void:
	_spawn_transform = Transform3D(Basis(Vector3.UP, t.basis.get_euler().y), t.origin)


## Cutscene_StartManual / PLAYER_CSACTION: he stands where he is, takes no
## orders and no blows, and plays `cs_anim` (the scene picks his poses).
func begin_cutscene() -> void:
	begin_talk(null)
	_drop_held()
	_cancel_boomerang()
	_set_sword_drawn(false)
	speed_oot = 0.0
	velocity = Vector3.ZERO
	in_cutscene = true
	cs_anim = &"idle"


func end_cutscene() -> void:
	in_cutscene = false
	cs_anim = &""
	end_talk()


func end_talk() -> void:
	item_get = false
	talk_partner = null
	combat.cancel_attack()
	combat.clear_buffer()
	if state == State.TALK:
		_change_state(State.IDLE)


func _state_talk(delta: float) -> void:
	speed_oot = move_toward(speed_oot, 0.0, stop_decel * _frames(delta))
	if item_get:
		return
	if in_cutscene:
		if cs_anim != &"" and model.anim.has_animation(cs_anim):
			model.play(cs_anim, 0.15)
		return
	if is_instance_valid(talk_partner):
		_face_toward(talk_partner.global_position, 3000.0, delta)
		move_yaw = facing_yaw
	model.play(&"idle", 0.15)


## Starts easing the model from `world_offset` (relative to the body) back to it.
func _start_model_offset(world_offset: Vector3, duration: float, two_phase: bool) -> void:
	_offset_from = Basis(Vector3.UP, facing_yaw).inverse() * world_offset
	_offset_dur = maxf(duration, 0.001)
	_offset_time = 0.0
	_offset_two_phase = two_phase
	model.position = _offset_from


## Climbs rise first and then move in over the top; other moves ease straight.
func _update_model_offset(delta: float) -> void:
	if in_sand > 0.0:
		in_sand -= delta
	else:
		sink = move_toward(sink, 0.0, 2.0 * delta)
	if _offset_time >= _offset_dur:
		model.position = Vector3(0, -sink, 0)
		return
	_offset_time += delta
	var t := clampf(_offset_time / _offset_dur, 0.0, 1.0)
	if _offset_two_phase:
		var ky := smoothstep(0.0, 0.7, t)
		var kz := smoothstep(0.35, 1.0, t)
		model.position = Vector3(_offset_from.x * (1.0 - kz), _offset_from.y * (1.0 - ky), _offset_from.z * (1.0 - kz))
	else:
		model.position = _offset_from * (1.0 - smoothstep(0.0, 1.0, t))
	model.position.y -= sink


## Walk/run animation rate from the OoT walk cycle: a 29-frame stride advanced by
## 0.55 + 0.27 * speed frames per game frame, blending into the run above speed
## 3.7 and running at 1.2 + 0.35 * (speed - 3.7) once fully blended.
func _animate_ground() -> void:
	var s := speed_oot
	if is_z_targeting() and s > 0.1 and z_move != ZMove.FORWARD:
		var rel := angle_difference(facing_yaw, move_yaw)
		if absf(rel) > PI / 4.0 and absf(rel) < PI * 0.75:
			var rate := (0.55 + 0.27 * s) * OOT_RATE * OOT_FPS / 29.0
			model.play(&"sidestep", 0.1, rate * 0.6 * (1.0 if rel < 0.0 else -1.0))
			return
		if absf(rel) >= PI * 0.75:
			var rate := (0.55 + 0.27 * s) * OOT_RATE * OOT_FPS / 29.0
			model.play(&"walk", 0.1, -rate * 0.84)
			return
	if s <= 0.05:
		model.play(&"idle", 0.15)
		return
	var frames_per_tick: float
	var blend := 0.0
	if s < 3.7:
		frames_per_tick = 0.55 + 0.27 * s
	else:
		blend = 0.6 * (s - 3.7)
		frames_per_tick = 0.55 + 0.27 * s if blend < 1.0 else 1.2 + 0.35 * (s - 3.7)
	var cycles_per_sec := frames_per_tick * OOT_RATE * OOT_FPS / 29.0
	if blend >= 0.5:
		model.play(&"run_sword" if sword_drawn and not Equipment.two_handed() else &"run", 0.1, cycles_per_sec * 0.56)
	else:
		model.play(&"walk", 0.1, cycles_per_sec * 0.84)


## Footsteps (func_8084029C): OoT plays the stepping sound at frames 10 and 24
## of its 29-frame walk cycle, as each foot comes down, using the floor's
## surface sound (Player_PlaySteppingSfx) raised in pitch and volume by speed.
## Our walk, run, side-step and turn cycles put a foot down at the start and
## halfway through, in either playing direction.
func _update_footsteps() -> void:
	var a := model.anim
	if not is_on_floor() or not (model.current_anim in STEP_ANIMS) or not a.is_playing() or a.current_animation_length <= 0.0:
		_step_phase = -1.0
		return
	var phase := fposmod(a.current_animation_position / a.current_animation_length, 1.0)
	if _step_phase >= 0.0:
		var fwd := a.speed_scale >= 0.0
		for c in [0.0, 0.5]:
			if _crossed(_step_phase if fwd else phase, phase if fwd else _step_phase, c):
				_footstep()
				break
	_step_phase = phase


## True if going forward from phase `a` to `b` (wrapping at 1) passes `c`.
static func _crossed(a: float, b: float, c: float) -> bool:
	if b >= a:
		return c > a and c <= b
	return c > a or c <= b


## One footstep (or a landing) on whatever is underfoot. OoT raises the
## stepping sound with speed; here the pace carries a wide range (a creep is
## barely there, a run is clear), every step varies a little at random, and
## each surface has its own trim (Surface.STEP_TRIM: hard floors sit lower).
## A landing is as loud as the fall was hard (`impact`, the speed hitting the
## ground in m/s). Fresh out of the water, the steps squelch.
func _footstep(landing := false, impact := 0.0) -> void:
	var s := Surface.under(get_world_3d(), global_position, World.area_node)
	if s == "":
		return
	last_surface = s
	var db := footstep_db(s, speed_oot / run_speed_limit, landing, impact)
	var k := clampf(speed_oot / run_speed_limit, 0.0, 1.0)
	var pitch := (0.82 if landing else 0.94 + 0.12 * k) * randf_range(0.96, 1.04)
	Sfx.play_step(Surface.step_sound(s, _foot), db, pitch)
	if wet_time > 0.0 and s != "water":
		Sfx.play_step("step_wet_%d" % (_foot % 2), db - 3.0 + wet_time / WET_TIME * 3.0, pitch)
	elif Weather.wet_ground(s):
		# Soft ground squelches in the rain.
		Sfx.play_step("step_wet_%d" % (_foot % 2), db - 5.0, pitch)
	_foot += 1


## How loud a step is, in dB: `pace` is the speed over the run speed (0..1),
## and landings go by `impact` instead. Random spread of +-STEP_SPREAD dB.
static func footstep_db(surface_name: String, pace: float, landing := false, impact := 0.0) -> float:
	var trim: float = Surface.STEP_TRIM.get(surface_name, 0.0)
	var base: float
	if landing:
		# A hop off a step is a soft pat; a long drop is a thud.
		base = lerpf(STEP_QUIET_DB + 2.0, STEP_LOUD_DB + 4.0, clampf(impact / 16.0, 0.0, 1.0))
	else:
		var k := clampf(pace, 0.0, 1.0)
		base = lerpf(STEP_QUIET_DB, STEP_LOUD_DB, k * k * (3.0 - 2.0 * k))
	return base + trim + randf_range(-STEP_SPREAD, STEP_SPREAD)


## func_8083DDC8: above speed 5 the chest pitches forward by speed * 200 units
## and rolls into turns; the head counters half of it.
func _update_lean(delta: float) -> void:
	var pitch := 0.0
	var roll := 0.0
	if state == State.MOVE and not is_z_targeting() and speed_oot > 5.0:
		pitch = minf(speed_oot * 200.0, 4000.0) * BINANG
		roll = clampf(-angle_difference(facing_yaw, move_yaw) / BINANG * speed_oot * 0.1, -4000.0, 4000.0) * BINANG
	_lean.x = _step_angle(_lean.x, pitch, 900.0, delta)
	_lean.y = _step_angle(_lean.y, roll, 200.0, delta)
	model.lean = _lean


func _face_toward(point: Vector3, binang_step: float, delta: float) -> void:
	var to := point - global_position
	if Vector2(to.x, to.z).length() < 0.05:
		return
	facing_yaw = _step_angle(facing_yaw, _yaw_of(to), binang_step, delta)


func _change_state(new_state: State) -> void:
	if state == new_state:
		return
	if state == State.ATTACK and new_state != State.ATTACK:
		combat.cancel_attack()
	if state == State.ITEM and new_state != State.ITEM:
		items.end_action()
	if state == State.JUMPSLASH:
		combat.end_jumpslash()
		if _thrust:
			_thrust = false
			combat.end_thrust()
	if new_state != State.MOVE:
		z_move = ZMove.NONE
	if new_state != State.AIR:
		_hop = false
	if state == State.BLOCK:
		if combat.stabbing:
			combat.cancel_attack()
		shield_aim = Vector2.ZERO
		model.upper_turn = Vector2.ZERO
	if new_state in [State.LOOK, State.AIM] and sword_drawn:
		# First person: the sword goes back in its sheath (OoT's items are
		# held in both hands; the blade never hangs in front of the view).
		_set_sword_drawn(false)
	state = new_state
	_state_time = 0.0
	state_changed.emit(new_state)


# --- Damage -------------------------------------------------------------------

## Called by the Hurtbox. Returns a Hurtbox.Result.
func take_hit(info: HitInfo) -> int:
	if state == State.DEAD or _invuln_time > 0.0:
		return Hurtbox.Result.IGNORED
	if state == State.TALK:
		return Hurtbox.Result.IGNORED
	var shield := Equipment.guard()
	# A dungeon's tougher creatures hit harder (EnemyScale).
	if info.attacker is Enemy:
		info.damage = EnemyScale.damage(info.damage, (info.attacker as Enemy).tier)
	# The Iron and Mirror Shields stop even blows too heavy for the Wooden Shield.
	var stoppable: bool = not info.unblockable or shield.get("heavy", false)
	# The Parry: a bash timed to the blow turns it and staggers the attacker.
	if combat.is_parrying() and combat.can_block_from(info.source_position) and stoppable:
		Sfx.play("shield_block", 2.0, 0.0, 1.35)
		Sfx.play("sword_hit", -2.0, 0.0, 1.5)
		Fragments.burst(get_parent(), load("res://assets/models/shard_mesh.tres"), global_position + Vector3.UP * 1.1 + shield_forward() * 0.6,
			8, 3.0, 2.0, 0.25, 0.2, Color(2.0, 1.8, 1.2))
		GameManager.rumble(0.6, 0.15)
		if is_instance_valid(info.attacker) and info.attacker.has_method("parried"):
			info.attacker.call("parried", self)
		parried.emit()
		return Hurtbox.Result.BLOCKED
	if is_shielding() and combat.can_block_from(info.source_position) and stoppable:
		combat.on_blocked()
		var push_dist: float = shield.block_push * (2.0 if info.unblockable else 1.0)
		var push := _flat_dir_from(info.source_position) * push_dist
		velocity.x = push.x
		velocity.z = push.z
		if state == State.BLOCK:
			model.play(&"block_crouch_hit", 0.02, 1.0, true)
		GameManager.rumble(0.4, 0.15)
		return Hurtbox.Result.BLOCKED
	health.apply_damage(Progress.defended(info.damage))
	Sfx.play("player_hurt")
	GameManager.rumble(0.8, 0.3)
	_drop_held()
	if health.is_dead:
		return Hurtbox.Result.HIT
	if is_riding():
		_invuln_time = invulnerability_time
		_blink_time = 0.0
		return Hurtbox.Result.HIT
	# A hit knocks him off a ledge or ladder and out of the bow and first person.
	_reset_actions()
	var kb := _flat_dir_from(info.source_position) * info.knockback
	velocity.x = kb.x
	velocity.z = kb.z
	velocity.y = 2.5
	speed_oot = 0.0
	_invuln_time = invulnerability_time
	_blink_time = 0.0
	_change_state(State.HURT)
	model.play(&"hurt", 0.02, 1.0, true)
	return Hurtbox.Result.HIT


func _flat_dir_from(source: Vector3) -> Vector3:
	var d := global_position - source
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else -forward()


func _on_died() -> void:
	# A fairy in a bottle brings him back (OoT: she flies out as he falls).
	_fairy_revive = Progress.take_from_bottle("fairy")
	if is_riding():
		dismount()
	combat.cancel_attack()
	_clear_z_targeting()
	_reset_actions()
	_change_state(State.DEAD)
	model.play(&"death", 0.05, 1.0, true)
	model.visible = true


## The fairy swirls round him and he gets up with eight hearts.
func _revive_by_fairy() -> void:
	_fairy_revive = false
	Sfx.play("fairy_heal", 0.0, 0.0)
	health.health = mini(Fairy.HEAL, health.max_health)
	health.health_changed.emit(health.health, health.max_health)
	Fragments.burst(get_parent(), load("res://assets/models/leaf_mesh.tres"), global_position + Vector3.UP * 1.0, 16, 2.0, 3.0, 1.0, 1.0, Color(2.0, 1.4, 1.8))
	_change_state(State.IDLE)
	model.play(&"idle", 0.2)


## Walks the hero along `dir` (world space, length = stick tilt 0..1) for `time`
## seconds, ignoring player input meanwhile.
func auto_walk(dir: Vector3, time: float, tilt := 0.85) -> void:
	_clear_z_targeting()
	_auto_walk_dir = Vector3(dir.x, 0.0, dir.z).normalized() * tilt
	_auto_walk_time = time
	input_enabled = false


func _fell_out() -> void:
	void_out(fall_damage)


## Puts away the bow, leaves first person and any climb (death, void-out, respawn).
func _reset_actions() -> void:
	if is_riding():
		dismount()
	if is_instance_valid(hook):
		hook.release()
		hook = null
	_end_bow_z()
	_cancel_boomerang()
	_drop_held()
	aim_item = ""
	bow_phase = Bow.NONE
	model.set_bow_out(false)
	_offset_time = _offset_dur
	model.position = Vector3.ZERO
	_ledge = {}
	_ledge_type = 0
	_ladder_dir = 0
	if is_first_person() and camera_rig:
		camera_rig.snap_behind_target()


## Returns the hero to where he entered the area (OoT void-out), costing `damage`.
func void_out(damage: int) -> void:
	_reset_actions()
	velocity = Vector3.ZERO
	speed_oot = 0.0
	global_transform = _spawn_transform
	facing_yaw = _spawn_transform.basis.get_euler().y
	move_yaw = facing_yaw
	if camera_rig:
		camera_rig.snap_behind_target()
	if state == State.DEAD:
		return
	if damage <= 0:
		_change_state(State.IDLE)
		return
	health.apply_damage(damage)
	Sfx.play("player_hurt")
	if not health.is_dead:
		_invuln_time = invulnerability_time
		_change_state(State.IDLE)


func respawn() -> void:
	_reset_actions()
	global_transform = _spawn_transform
	facing_yaw = _spawn_transform.basis.get_euler().y
	move_yaw = facing_yaw
	rotation.y = facing_yaw
	velocity = Vector3.ZERO
	speed_oot = 0.0
	health.reset()
	combat.cancel_attack()
	_clear_z_targeting()
	_invuln_time = 1.5
	_change_state(State.IDLE)
	model.play(&"idle", 0.0, 1.0, true)
	if camera_rig:
		camera_rig.snap_behind_target()
	respawned.emit()


func _update_blink(delta: float) -> void:
	if is_first_person() and aim_camera_back() > 0.0 and aim_arms_only:
		# The camera is behind his head: only his arms are drawn.
		model.visible = true
		model.set_arms_only(true)
		return
	model.set_arms_only(false)
	if is_first_person() and aim_camera_back() <= 0.0:
		# The view is from his eyes: the body is not drawn (as in OoT).
		model.visible = false
		return
	if _invuln_time > 0.0 and state != State.DEAD and _blink_time >= 0.0:
		_blink_time += delta
		model.visible = fmod(_blink_time, 0.12) < 0.07
	else:
		if _invuln_time <= 0.0:
			_blink_time = 0.0
		model.visible = true


# --- Targeting (separate from camera realignment) -----------------------------

## Player_UpdateZTargeting.
func _update_targeting() -> void:
	# Attention_ShouldReleaseLockOn: the target died or left the leash range.
	if lock_target and (not is_instance_valid(lock_target) or not lock_target.is_targetable() \
			or global_position.distance_to(lock_target.global_position) > target_range * 1.4):
		lock_target = null
	if not input_enabled or state == State.DEAD or is_climbing() or state == State.TALK:
		_clear_z_targeting()
		return
	if Input.is_action_just_pressed("target"):
		if lock_target:
			# Only reachable in Switch mode: Z again moves on to another target, or lets go.
			lock_target = _find_target(lock_target)
		else:
			var next := _find_target()
			if next:
				lock_target = next
				_lock_switch = not GameManager.z_target_hold
			elif not parallel:
				_set_parallel()
	if not Input.is_action_pressed("target"):
		parallel = false
		if lock_target and not _lock_switch:
			lock_target = null
	if lock_target:
		parallel = false


## Player_SetParallel: freeze the current facing; the camera swings behind it.
func _set_parallel() -> void:
	parallel = true
	parallel_yaw = facing_yaw
	if state == State.MOVE:
		z_move = ZMove.FORWARD


func _clear_z_targeting() -> void:
	lock_target = null
	parallel = false


func _find_target(exclude: Enemy = null) -> Enemy:
	var best: Enemy = null
	var best_score := INF
	var view_fwd := camera_rig.forward_vector() if camera_rig else forward()
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy == exclude or not enemy.is_targetable():
			continue
		var to := enemy.global_position - global_position
		var dist := to.length()
		if dist > target_range:
			continue
		var flat := Vector3(to.x, 0, to.z).normalized()
		# Prefer enemies in front of the camera / player.
		var facing_bonus := maxf(flat.dot(view_fwd), flat.dot(forward()))
		if facing_bonus < -0.2:
			continue
		if not _target_in_sight(enemy):
			continue
		var score := dist * (1.5 - facing_bonus)
		if score < best_score:
			best_score = score
			best = enemy
	return best


## Attention_FindTargetableActorInCategory's BgCheck line test: nothing can be
## locked onto through a wall, floor or ceiling (e.g. rats a storey below).
func _target_in_sight(enemy: Enemy) -> bool:
	var from := global_position + Vector3.UP * 1.4
	var to := enemy.global_position + Vector3.UP * enemy.target_height()
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	q.exclude = [get_rid(), enemy.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _update_marker(delta: float) -> void:
	target_marker.visible = lock_target != null
	if lock_target:
		target_marker.global_position = lock_target.marker_point()
		target_marker.rotate_y(3.0 * delta)
