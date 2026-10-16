# Technical notes

> These notes were written while the systems were first built (alpha through beta 1.0.0) and are kept for reference. Some details have changed since; `patch_notes/` lists every change, and the code comments are the current source of truth.

## Running the game

1. Open **Godot 4.7.2** and choose **Import** in the Project Manager. Select this folder's `project.godot`.
2. Press **F5** (Run Project). The main scene is `res://scenes/main.tscn`.
3. Press **Enter** (or Space / E / left click) on the title screen.

From a terminal:

```
Godot_v4.7.2-stable_win64.exe --path "G:\Games\Godot Games\giggle-64"
```

Optional command-line flags (put them after `--`):

- `--skip-title` starts directly in gameplay.
- `--automation` never captures the mouse and never auto-pauses on focus loss. The test tools use it.
- `--fps=21` (or 30 / 60) overrides the saved frame-rate setting for that run.

## Controls

An Xbox (XInput) controller is the intended way to play. Godot reads XInput pads
natively; just plug one in. The layout follows Ocarina of Time's N64 buttons:

| Action | Xbox controller | Keyboard / mouse |
|---|---|---|
| Move (analog: light tilt turns on the spot, half tilt walks, full tilt runs) | Left stick (or D-pad) | WASD / arrow keys (hold Ctrl to walk) |
| A: interact when something is in reach (OPEN a door, SPEAK to someone, GRAB a pot, rock or shrub, CLIMB a block); otherwise roll (stick pushed) or "Put Away" the sword (stick neutral). A never jumps. | A | Space or E |
| Throw what you are carrying | A, B, X or Y | Space, left mouse, 1 or 2 |
| A while Z-targeting: **jump slash** (stick neutral or forward, sword in hand or locked on; otherwise a roll), side hop (stick left/right), back flip (back) | A + left stick | Space + direction |
| B in mid-air (any jump or side hop but the back flip): jump slash | B | Left mouse |
| Swimming: A dives (hold to go deeper); push against a low bank to climb out | A | Space |
| Riding: A beside Biscuit mounts; A spurs her on (6 carrots) or, standing still, gets off; B swings the sword; the bow aims from the saddle | A / B / X / Y | Space / left mouse / 1 / 2 |
| Fishing at Mira's dock: hold A to wind up and release to cast, A to hook a bite and hold to reel; B puts the rod away | A / B | Space / left mouse |
| Pause screen: B asks to save the game | B | Left mouse |
| Sword (tap again for a 2-hit combo); draws the sword if it is on his back | B | Left mouse button (or J) |
| Shield (hold): crouch behind it; while Z-targeting it is held up standing and he can strafe | RT | Right mouse button (or K) |
| Item buttons (OoT's C-Left / C-Right): use the item on that button. The bow starts on X. | X / Y | 1 / 2 (or U / O) |
| First-person view (OoT's C-Up): look around; A, B, R or the button again returns | RB | F (or I) |
| Look / aim in first person | Left stick (or right stick) | Mouse (or WASD) |
| Shoot while aiming: release the item button, or click | release X / Y | release 1 / 2, or left click |
| Z-target: lock on to an enemy. With nothing in range, **hold** to strafe (parallel mode) | LT | Q, L or middle mouse |
| Recenter camera behind the hero | LB | Shift |
| Orbit and tilt the camera (CAMERA: MODERN only) | Right stick | Mouse |
| Pause screen | Start | Esc |
| Pause screen: previous / next page (OoT's Z / R) | LT / RT | Q / right mouse (or K) |
| Pause screen, SELECT ITEM: put the item under the cursor on a button | X / Y | 1 / 2 |
| Text boxes: show the rest / next box / pick a choice | A (B also shows the rest) | Space |
| Minimap on / off (OoT's L) | Back / View | M |
| Toggle fullscreen | | F11 |

With the default CLASSIC camera the right stick and the mouse never move the third-person
camera (as in OoT); they only look and aim in first person. The pause screen's CAMERA option
switches to MODERN, where they orbit it (see Camera below).
The HUD and pause menu switch their button prompts
between controller and keyboard depending on what you last touched. Hits, blocks,
sword strikes and roll bonks make the controller rumble (can be turned off in the pause menu).

## The overworld: the land of Haven

A new game starts outside the hero's home in **Haven Village**. `tools/gen_world.gd` generates
every area from its region file in `tools/world/regions/`:

| Area | Where | Highlights |
|---|---|---|
| Bunsriel Fields | The hub, about Hyrule Field's size (~230 × 200 m) | Rolling hills, dirt roads from a central crossroads, the snowmelt river with three bridges, a lone great tree, a stone ring, a pond, two sealed caves. The castle and a snowy peak stand on the horizon. |
| Haven Village | South of the field | The hero's home on its mound, plaza and fountain, shops, houses, library, well, bell tower |
| Old Castle Town | North | A walled market town of tall painted houses on blue-gray cobbles, market square, canal, temple, and the sealed Castle of Bunsriel (the final dungeon) |
| The Forest | North-west | Giant trunks in heavy lilac fog, a pond, a sealed cave, and the stone gate to the Hidden Forest |
| The Hidden Forest | Beyond the forest gate | A misty lake, three standing stones, the great tree and an empty pedestal |
| West Marshlands | West | Shallow channels, dead trees, boardwalks, a hut on stilts, the Bog Tower in deep water |
| Southern Fields | South-west, also reached from the village | Farm, plowed fields, windmill, orchard, pond, the brick Southern Tower |
| Desert of Ladhellin | East | Dunes, mesas, a rock arch, an oasis, ruins, Ladhellin Tower |
| Northeastern Cliffs | North-east | A four-tier climb of orange rock with switchback ramps and three waterfalls; a sealed mini-dungeon door |
| Frostpeak | At the top of the cliffs | Snowfall, a frozen lake, snowy pines, ice spires, a mountain hut, the Frost Shrine |
| The South Road | South-east, also reached from the desert | A red-rock canyon road, a gorge with a railed bridge, a ruined watchtower |
| Mirror Lake | At the end of the South Road | Beaches, a dock, a chain of bridges over islets to the domed Lake Shrine (its door leads down into the dungeon), Mira's lookout house (a door inside, a ladder to the roof deck) and three archery targets on the shore |
| Mira's House | Inside her house at the lake | Hearth, bed, table, shelves of jars, fishing gear, and Mira herself |
| The Lake Shrine | Under the island in Mirror Lake | The first dungeon (see below) |

- **Loading screens** follow OoT's timing from the decomp (`z_fbdemo_fade.c`, `z_play.c`):
  - a 1 s fade to black while the hero keeps walking into the exit
  - a short black hold
  - a 1 s fade in while he walks out of the entrance
  - the place-name card (`TitleCard_InitPlaceName`): a 20-frame delay, a fade in, 80 frames on screen, then a fade out
- Each area has its own fixed **mood**: a painted cloud sky, fog color and range, ambient
  light, and OoT's two directional lights (`EnvLightSettings` light1 and light2).
- Apart from the Lake Shrine, dungeon doors and caves are **sealed** for now.
- There is no swimming yet, so deep water (the Bog Tower's moat, the middle of Mirror Lake)
  returns the hero to the entrance. Falling into the South Road's gorge is a normal void-out.
- Health carries over between areas. Dying or falling returns the hero to the entrance he
  came in by.

## Sound: footsteps and ambience

- **Footsteps** follow OoT's `func_8084029C`: a step plays each time a foot comes down in the
  walk, run, side-step and turn cycles, a little louder and higher the faster the hero goes.
  Landings use the same sounds, heavier.
- The sound depends on the **surface** underfoot, like OoT's `SurfaceSfxOffset` per floor
  polygon: grass, dirt, sand, stone, wood, water, snow, ice, mud and carpet
  (`scripts/systems/surface.gd`).
  - Each area's terrain carries a baked 1 m grid of surfaces, read from its painted ground
    colors (regions can override this, such as Mira's floorboards and the marsh mud).
  - Bridges, decks, crates and ladders are wood; buildings and paving are stone.
  - Wading in shallow water splashes.
- Every region has its own **ambience** loop under the music (`WorldData.AREAS` "ambience"):
  birds and breeze in the field and village, the market crowd in Castle Town, a deep hush and
  an owl in the forest, chimes in the Hidden Forest, frogs and insects in the marsh, crickets on
  the farm, dry wind in the desert, gusts and a hawk on the cliffs, a blizzard on Frostpeak,
  lapping water and gulls at the lake, a crackling hearth at Mira's, and dripping water in
  the shrine. All of it is synthesised by `tools/gen_sounds.gd`.

## Life in the overworld

Each region's `populate()` (in `tools/world/regions/`) places its creatures, grass, pots,
rupees and signs on open ground (the world kit keeps a map of everything solid it has built).

| Creature | After OoT's | Where | Behavior |
|---|---|---|---|
| Tektite (red, blue) | `EnTite` | Field hills, cliffs, South Road, Frostpeak (blue) | Turns to face you, crouches and jumps: attack jumps within 5.4 m, hops closer from up to 9 m, one to three in a row |
| Keese | `EnFirefly` | Forest, cliffs, the shrine | Hovers by its roost, then dives at your head in a weaving line and flies off to dive again |
| Snapper | `EnDekubaba` | Forest, field edge, marsh, farm pond (coral ones in the shrine) | Hidden under its leaves until you come near; rises, sways, rears back and bites; a hit stuns it |
| Leever | `EnReeba` | Desert | Burrows to a spot just ahead of you, bursts up spinning, chases for a few seconds, sinks |
| Octorok | `EnOkuta` | The river, the marsh, Mirror Lake | Pops up out of the water and spits rocks. Catch one on the shield and it flies back and kills it |

- **Grass** (`scripts/items/shrub.gd`, after `En_Kusa`): the sword, an arrow or the boomerang
  cuts it; leaves fly, it drops from OoT's drop table 0, and it grows back after 120 frames.
- **Lifting and throwing** (see below): pots, small rocks and grass can be picked up with A and
  thrown.
- **Small rocks** (`scripts/items/lift_rock.gd`, after `En_Ishi`) lie in the field, on the South
  Road, the cliffs, the desert, by the lake and on Frostpeak. The sword clangs off them; lift and
  throw them to break them.
- **Pots** (`scripts/items/pot.gd`, after `Obj_Tsubo`): break with the sword, an arrow or the
  boomerang. They hold a set item or a random drop.
- **Drops** follow `Item_DropCollectibleRandom` with OoT's drop tables (`scripts/items/drops.gd`).
  A heart at full health becomes a green rupee, nothing is dropped that the hero cannot use,
  and the "flexible" slot gives what he needs most.
- **Rupees, hearts, arrows and keys** (`scripts/items/collectible.gd`, after `EnItem00`):
  - dropped items pop up, bounce, and vanish after 11 seconds (flickering for the last 2)
  - placed ones stay; rupees spin; a recovery heart floats down swaying
  - touch one, or strike it with the sword, an arrow or the boomerang, to collect it
  - green 1, blue 5, red 20; the first wallet holds 99
- The **HUD** shows the rupee count at the bottom left (padded and colored like OoT's
  counter), and the small-key count above it inside a dungeon.
- **Signposts** (`scripts/items/signpost.gd`, after `En_Kanban`) stand at every region's way
  in and at the field's forks. Read one from the front with A (the A button says CHECK); the
  text appears at once in OoT's wooden text box. The sword cuts the board off its post.
- The village and Castle Town have no monsters, only grass, pots and hidden rupees.

## The Lake Shrine (the first dungeon)

The door in the domed shrine on the island in Mirror Lake leads down into the Lake Shrine: a
sunken temple of blue-green stone carved with waves, hung with coral, full of falling water and
dripping echoes. It is themed on water, but nothing in it needs swimming.

- **Rooms**: the Entry Hall; the Bell Hall (the hub, with a pool under a great bronze bell and
  the boss door up on its north gallery between two falls); the Coral Hall; the Sunken Bridge
  room; the Knight's Hall; the Gallery of Falls; the Hall of the Key; and the Abyssal Chamber.
- **Dungeon systems**, after OoT's:
  - **Shutters** slam shut when you enter a room with monsters and lift when they are beaten
    (`Door_Shutter`); the secret jingle plays and any chest the room was hiding appears.
  - **Chests** (`En_Box`): small and big. Opening one plays the get-item scene: the hero holds
    the treasure up while a fanfare plays and a box names it.
  - **Small keys** open locked doors (chains and a padlock) and only work in this dungeon.
  - The **Dungeon Map** shows the rooms on the pause screen's map page, and the **Compass**
    adds the chests and the boss's lair.
  - The **Boss Key** opens the boss door.
  - **Crystal switches** (strike them) and **floor switches** (step on them) move bridges and bars.
  - **Thrown pots and rocks** solve two optional puzzles, each with a red rupee chest:
    - In the Entry Hall a wall of brittle coral seals the north-west corner. The sword, arrows
      and the boomerang clang off it; a pot thrown at it breaks it.
    - In the Bell Hall a floor switch sits on a pedestal too tall to climb. A pot thrown up
      onto it (from about 6 m) presses it, and a chest appears beside it.
  - **Pits** return you to where you entered the room, a heart poorer (OoT's void-out).
  - **The great bell** over the Bell Hall's pool swings and tolls when an arrow or the
    boomerang strikes it (`scripts/dungeon/temple_bell.gd`). Toll it three times in a row and
    the offerings hidden in its crown come loose: a shower of rupees, once.
- **Creatures**:
  - **Drowned Stalfos** (`EnTest`): skeleton swordsmen that circle you, block blows and arrows
    from in front with their shields, slash and leap in with overhead chops, and hop back when hurt.
  - **Shell Blades** (`EnSb`): clams that hop at you shut (blows clang off), then open to bite.
    Strike them while they are open, or knock them open and dazed with the boomerang.
  - **Keese** and coral **Snappers**.
- **The Tide Knight** (mini-boss, after the Iron Knuckle, `EnIk`): a huge knight in barnacled
  plate with a cleaver. It plods after you and never flinches. Close in front it raises the
  cleaver and chops down (too heavy for the shield); at its side or back it sweeps all round.
  After each attack it stands open. Half beaten, it throws off its armor and fights faster.
  Its reward is the dungeon's treasure, the Boomerang.
- **Carapax** (the boss): a giant armored crab with one great eye on a stalk. Its fight
  follows Gohma's: the shell turns every blow. Strike the eye with an arrow or the boomerang
  and it is thrown on its back, legs kicking, with its soft underside open to the sword. It
  sidles round you out of reach, slams a claw down when you come close, charges across the
  chamber (and reels, dazed, if it hits a wall), and blows bubbles that drift after you (the
  sword or shield pops them). At half strength it gets faster and blows more bubbles. It has
  a name card when it appears.
- Beating it leaves a **heart container** (one more heart, all refilled) and the **blue warp**
  that carries you out onto the island.
- Mira has something to say about the shrine, before and after.

## The Boomerang

Put it on X or Y in the SELECT ITEM screen. **Hold** that button to aim it and **release** to
throw it, as in OoT (`func_80834EB8`, `func_808358F0`):
- A reticle marks the middle of the view. When it lies on something within the boomerang's
  reach (a wall, the floor, a creature, an item), the boomerang leaves his hand straight for
  that point. Otherwise it skims out along the aim at hand height, as in OoT, low enough to
  sweep up items on the ground.
- On the ground the camera moves to OoT's `CAM_MODE_AIM_BOOMERANG`: 50 units (1.5 m) behind the
  hero's head, letterboxed, and the stick (or mouse) turns and tilts the aim as with the bow.
  As in OoT, only his arm and the boomerang are drawn. Releasing throws it along the aim, up or
  down included. B, A or RB puts it away without throwing.
- While Z-targeting it is readied on the upper body (he keeps moving and the view stays in third
  person); releasing throws it at the target.
- In the air it is thrown straight away.

In flight it follows OoT's `EnBoom`:
- It flies at 12 units a frame (about 10.8 m/s) for 20 frames, then turns for home and flies
  back; you catch it within 40 units. Only one can be out at a time, and you can move meanwhile.
- While Z-targeting it sets off to the side and curves in on the target.
- Hitting a wall, a creature or a switch sends it straight back.
- It stuns most creatures (keese fall to it), flips crystal switches, cuts grass, breaks pots,
  and carries back any item it touches (the shrine hides a key it alone can reach).

## Lifting and throwing (from `z_player.c`, `z_obj_tsubo.c`, `z_en_ishi.c`, `z_en_kusa.c`)

- **GRAB:** a pot, small rock or shrub in reach offers itself to A (OoT's `Actor_OfferGetItem`).
  He must face it within 45 deg; the most squarely faced one wins.
  - Pots: within 30 units (0.9 m). Rocks and shrubs: within 50 units (1.5 m) and 10 units of height.
- **Lifting** puts the sword away, squats, takes hold on frame 4 and raises it overhead
  (OoT's `carryB`). He then walks, runs, Z-targets and falls off ledges carrying it, but does not
  roll, swing, shield, look in first person, climb (except small hops), use ladders or hang from edges.
- **THROW:** A, B or an item button throws it (OoT's `Player_ActionHandler_9`). On frame 3 of the
  throw it leaves with his speed + 8 and 12 up (`func_8084409C`); pushing the stick ends the throw
  from frame 8. Z-targeting, he faces the target, so it goes at the target.
- **In flight** each object follows its own actor:
  - pots and rocks fall with gravity -1.2 and land about 8 m away
  - shrubs fall with gravity -3.2 and lose 5% of their speed a frame, so they land sooner
  - all of them tumble, break on the ground, a wall or deep water, and drop their item
- A thrown object that hits a creature deals 1 damage. It also breaks pots and cuts grass it hits.
- A lifted shrub is uprooted and grows back like a cut one.
- Getting hit makes him drop what he carries, and it breaks.

## Climbing (from `z_player.c`)

The hero climbs the way adult Link does, using his measurements from `sAgeProperties`.
When he pushes into a near-vertical wall, a probe drops from 111 units (3.3 m) above his
feet, just past the wall. A flat top 18-111 units up, with no ceiling or further wall in the
way, is a ledge:

| Ledge height | What happens (all automatic, like OoT) |
|---|---|
| under 18 units (0.5 m) | nothing; it is a step |
| 18-41 units (up to 1.2 m) | after 3 frames of pushing he hops up (`vy = height * 0.08 + 5.5`) |
| 41-59 units (up to 1.8 m) | after 6 frames, the short step-up |
| 59-79 units (up to 2.4 m) | after 6 frames, the tall step-up |
| 79-111 units (up to 3.3 m) | after 6 frames he jumps at the wall (`vy = height * 0.072`) and catches the edge |
| taller | not climbable |

- **Hanging:** in the air, touching a wall whose ledge is within reach (and at least 70 units
  over the floor), he grabs it. Walking slowly off a drop of more than 70 units, he turns round
  and hangs from the edge. Running off it (faster than speed 3) still jumps, as before.
- While hanging, push the stick to climb up. A lets go (as in OoT).
- **Blocks flagged for A:** these don't climb on their own. The A button says CLIMB (OoT's
  `WALL_FLAG_6`). Nothing in the overworld uses this yet.
- Fences, rails, posts, furniture and house roofs are never ledges.
- **Ladders** (OoT's `WALL_FLAG_1`): walk into one to grab it, and he snaps to its
  15-unit rungs.
  - Up and down climb one rung per step. The step speed follows how far the stick is pushed
    (OoT's `|stick| * 0.05`, 1-3.35).
  - He climbs over the top when there is floor 70 units up, and steps off the bottom.
  - A lets go.
  - Walking slowly off a ledge onto the top of a ladder grabs it going down.
- The first ladder is on the side of Mira's house: it leads up to her roof deck, which has a
  bundle of arrows.

## First-person view and the bow

- **First-person view:** RB (keyboard F) on the ground.
  - The camera slides into the hero's head (`Camera_Subj3`, FOV 45) and his body is hidden.
  - The stick turns him (16 units per frame per stick unit) and tilts the view (`stick_y * 240`,
    leveling off when let go), as in `func_8084ABD8`. The mouse turns and tilts too.
  - A, B, R or RB returns, and the A button says RETURN.
- **The bow:** the hero starts with it on X and 30 arrows (OoT's first quiver).
  - The item button draws it and the camera moves to OoT's `CAM_MODE_AIM_ADULT`: 50 units
    (1.5 m) behind the hero's head and a little below it, letterboxed, with a reticle at the
    center. As in OoT only his arms and the bow are drawn. Aiming uses OoT's curved stick rate,
    and the arrow leaves from his head along the line of sight, so it flies to the reticle.
  - The arrow is ready after the draw (`bow_ready`). Release the button (or click) to shoot;
    press again for the next arrow. A tap shoots as soon as the arrow is ready, as in OoT.
  - While Z-targeting, the bow comes out without leaving the third-person view and shoots
    at the target.
  - Arrows follow `EnArrow`:
    - 150 units per frame (about 135 m/s), dropping only in their last frames
    - they stick in walls for a second
    - an enemy takes 2 damage and the arrow bounces off
  - The archery targets ring a bell for a gold-center hit.
- **The reticle** (bow and boomerang) is white while readying and red once the shot is ready.
  It turns yellow-green while it lies on something the shot can hit within its reach: a
  creature, a switch, a pot, grass or an item (the boomerang's reach is its 10.8 m outbound
  flight). GRAPHICS > CROSSHAIR hides it.
- **Arrow bundles** (5 or 10) lie on Mira's roof and by the targets. Defeated goblins
  sometimes drop 5. Mira hands over 20 if you visit her with fewer than 10 (once).
- The pause screen's **CAMERA Y** option switches the first-person look between NORMAL
  and INVERTED (OoT's original, flight-stick style).

## People and text boxes

Mira lives in the house on the north shore of Mirror Lake. Her door opens with A ("OPEN") and
leads to her house, which is its own small area as in OoT. There is no title card for a house.

- She turns her head to follow the hero (OoT's `Npc_TrackPoint`), and turns to face him while
  they talk.
- Text boxes follow OoT's message system (`z_message.c`):
  - the box grows open over 8 frames (`Message_GrowTextbox`)
  - text types out one character per 20 Hz frame
  - A (or B) shows the rest at once
  - a green triangle means more, a square means the end
  - a two-choice box has a green cursor
  - key words are red
- The A button reads NEXT or DECIDE meanwhile, and the minimap hides.
- She is cute, quick to bristle and easily flustered. Her lines are in
  `scripts/npc/mira_lines.gd`. The first conversation includes a choice, and later visits cycle
  through a few chats.

## The big update: what's where and how it follows OoT

### Jump slash, wall clinks, alarms and counters
- **Jump slash** (`Player_ActionHandler_10` / `func_8083BA90`): Z-targeting with the stick neutral
  or forward and the sword ready, A leaps forward (speed 5, vy 5, hop gravity 1.2) with the sword
  raised; the blade is live from frame 6 and comes down in a landing chop. B in mid-air does the
  same from any jump or side hop but the back flip (`func_8083BBA0`: speed 3, vy 4.5). Jump attacks
  hit for double (OoT's `DMG_JUMP_*`). The A button says ATTACK when it will jump-slash.
- **Sword clinks** (`func_80842DF4`): a swing into a wall sparks, rings off it (hard or soft by the
  surface) and throws the hero back (speedXZ -14).
- **Low-health alarm** (`Health_UpdateBeatingHeart` / `Health_IsCritical`): a beep each heartbeat at
  one heart or less (more with more hearts).
- **Rupee counter** (`Interface_Update`'s accumulator): it ticks toward the purse a rupee per
  20 Hz frame, ten at a time when paying out 50 or more.

### Saving (`scripts/systems/save_game.gd`)
Three files (`user://save_0.json` to `save_2.json`) hold the whole of `Progress`, the area and
entrance to start from and the hero's health (at least three hearts back, as in OoT). The file
select shows each file's hearts and rupees, with CONTINUE and ERASE; an empty file starts a new
game (or picks a starting area, for testing). B on the pause screen asks "Would you like to save?"
(OoT's `PAUSE_STATE_SAVE_PROMPT`).

### Swimming
Deeper than 56 units he swims; shallower than 36 he wades out. He floats with his feet 44.8 units
down (`func_8084B000`). Speed builds only during each stroke's push (`func_8084AEEC`, at most 4.8).
A dives to 120 units (no scale); letting go he rises and surfaces. No sword or items in the water;
pushing against a low bank climbs out. Deep water no longer sends him back to the entrance.

### Biscuit (`scripts/horse/horse.gd`, after `z_en_horse.c`)
Walk / trot / gallop with base speeds 3 / 6 / 8, the cubic stick turn scaled by traction, braking
with the stick pulled back, six carrots (A) that boost to 14 and come back (60 frames, then every
11; 140 when all are spent), and automatic jumps over fences 19-72 units high. Clover's jumping
course in the Southern Fields corral wins her (the Sugar Cube) and, under 16 seconds, the Big
Wallet. Ride into the next open area and she comes along; into towns he goes on foot. Five
archery targets by the desert road in Bunsriel Fields hide a Piece of Heart.

### The Southern Tower and the Hookshot
An arrow shot through the lit torch below the tower catches fire and lights the braziers by its
door. Inside: the Granary (hub, Map), the Loom Room (Strawmen and a Gear Beetle; Small Key,
Compass), the Mill Room (the Rust Knight; the **Hookshot**), the Gear Hall up on the gallery
(hookshot across the gap; Boss Key) and the roof, where **Corvax** circles: hookshot it down,
then use the sword. The Hookshot (`z_arms_hook.c`): 20 units a frame for 13 frames (about 11.7 m),
pulls the hero to wooden targets at 30 a frame, stuns creatures, flips Gear Beetles and fetches
pickups. Targets also stand on the Bog Tower's islet and under the desert's rock arch.

### Town, quests and collectibles
- **Haven Library**: Ottilie, books on the reading tables and the Book of Haven on the lectern.
- **Marigold's Goods**: arrows, a recovery heart, a honey bun and the Big Quiver.
- **Pink's Armory** now sells the Red and Magical Swords and the Iron and Mirror Shields. The dearer
  ones need the Big Wallet.
- **The Bun Sword** waits in the Hidden Forest. Make the three standing stones' runes glow together
  (arrows, the boomerang or the sword) and it appears in the pedestal.
- **Fishing**: Mira lends her rod; the biggest fish (over ten pounds) earns her prize.
- **Pieces of Heart** (four make a heart): the library gallery, the Mirror Lake targets, the lake
  bed (dive), Mira's fishing prize, the field's archery, the desert arch, the cliffs' top tier and
  the Southern Tower's roof.

## Pause screen, minimap and settings

Start opens an OoT-style pause screen, modeled on `kaleido_scope`. Four pages stand on the
sides of a box. LT/RT (OoT's Z/R), or pushing the cursor past a page edge, swings to the next
page in perspective over 16 OoT frames, as `KaleidoScope_UpdatePageSwitch` does. The name
panel shows what the cursor is on.

- **SELECT ITEM**: the item grid and the hero's gear. The bow sits in the first slot with
  its arrow count, the boomerang beside it once found. Press X or Y (keyboard 1 or 2) over an
  item to put it on that button.
- **MAP**: an overhead map of all of Haven, after OoT's world map.
  - `tools/gen_world.gd` paints it from every region's own top-down map, laid out on the land,
    with the roads, the snowmelt river and mountains round the edge.
  - Every region has a dot. The current region's dot pulses blue and yellow every 20 frames,
    as in `KaleidoScope_DrawWorldMap`, and the top of the map says where you are. Inside a
    house it marks the region outside.
  - The cursor moves between the dots and the name panel names the region.
  - A shows the selected area's own map, with the hero's arrow when he is there.
  - Inside a dungeon the page shows that dungeon instead: its rooms once the Dungeon Map is
    found, the hero's arrow, and (with the Compass) the unopened chests and the boss's lair,
    with the small keys, map, compass and boss key held.
- **QUEST STATUS**: slots for the five dungeons, the three bun pieces and pieces of heart.
- **OPTIONS**:
  - Resume and Restart Area
  - Warp (debug): left/right picks any area, including the test area
  - **GRAPHICS >** opens its own list (B, Esc or BACK returns):
    - **FRAME RATE: 60 / 30 / 21 (OOT)**
    - **ANTI-ALIASING: ON / OFF**: the soft bilinear upscale of the 320 × 240 picture, or
      sharp nearest-neighbor pixels
    - **FOG: ON / OFF**: each area's depth fog
    - **CROSSHAIR: ON / OFF**: the aiming reticle
    - **FULLSCREEN**
  - **CAMERA: CLASSIC / MODERN** (see Camera below)
  - **CAMERA SPEED: SLOW / NORMAL / FAST** and **CAMERA X: NORMAL / INVERTED** (MODERN camera)
  - **RUMBLE**
  - **Z-TARGET: SWITCH / HOLD** (OoT's own option)
  - **CAMERA Y: NORMAL / INVERTED** (first-person look and aiming, and the MODERN camera's tilt)
  - **MINIMAP**
  - Quit

The **minimap** sits in the bottom-right corner, as in OoT's `Minimap_Draw`. It shows:
- the area's silhouette, tinted cyan
- a yellow-green arrow for the hero
- a red arrow where he entered
- gold marks on dungeon doors

Back/View or M toggles it. Settings are saved to `user://settings.cfg`.

**21 fps** reproduces how Ocarina of Time feels on an N64: its game logic runs at 20 Hz
on NTSC and the picture usually lands around 20-21 fps. In this mode both the physics
tick and the rendered frame rate are 21, so movement, animation and the camera all step
at that rate. Movement speeds are defined per second, so the hero covers the same
ground at every setting.

## Movement (from the Ocarina of Time decompilation): `scripts/player/player_controller.gd`

Sir Gigglebuns moves the way Link does. The behavior and tuning were worked out from
the [zeldaret/oot](https://github.com/zeldaret/oot) decompilation (`z_player.c`,
`z_player_lib.c`, `z_lib.c`); no code was copied. The controller keeps speeds in OoT
units per OoT frame and converts them (OoT logic runs at 20 Hz and moves actors by
velocity x 1.5 per frame; one unit is 3 cm, since adult Link is about 62 units tall).

- **Analog stick curve.** The stick is read as a 0-60 magnitude like the N64 stick. Below 20
  there is no speed; above it speed rises along OoT's cosine curve to the run cap of 6 units
  per frame (5.4 m/s). A light tilt from standstill turns in place.
- **Instant starts.** From standstill the hero faces the stick direction at once and runs.
- **Running turns.** Speed steps +2.0 / -1.5 per frame; the run direction turns at most about
  330 deg/s and the body follows it. Above speed 5 the chest leans forward and rolls into turns.
- **Reversing.** Pushing more than 135 deg away from the run direction stops dead and
  the hero runs off the other way, as in OoT.
- **A is the action button** (`Player_ActionHandler_Roll`, `Player_ActionHandler_10`). It first
  interacts with anything in the `interactable` group within reach in front of the hero (the node
  implements `interact(player)` and optionally `interact_label()`, shown on the HUD's A button);
  doors, signs and chests will hook in here. Otherwise, with the stick pushed (past 55 of 60) it
  rolls for about half a second at 1.5x the walking speed with brief invulnerability (a fast roll
  into a wall bonks him back). While Z-targeting, A + left/right side-hops, A + back back-flips.
  **A never jumps**: where OoT jump-slashes (Z + A, stick neutral) he rolls instead.
- **Sword on his back.** He starts with the sword sheathed in a scabbard across his back (hilt
  over the right shoulder). B draws it straight into the swing. Afterward the A button shows
  **PUT AWAY** once nothing else would use A for 1 second (OoT's 20-frame `putAwayCooldownTimer`
  in `Player_UpdateInterface`); A then sheathes it. The shield always stays in his left hand.
- **Shield** (`Player_ActionHandler_11`): without Z-targeting he crouches behind the shield with
  his feet planted (OoT's "defense" pose, `Player_Action_80843188`). While Z-targeting it is raised
  on the upper body only (`func_80834758` / `func_80834B5C`), so he can still strafe and side-step.
- **Z-targeting** follows `Player_UpdateZTargeting`:
  - Z with an enemy in range locks on. The body keeps facing the target; the stick walks,
    side-steps or backs off. Z again moves to another target or lets go (Switch mode).
  - Z with nothing in range starts **parallel mode** for as long as Z is held
    (`Player_SetParallel`): the facing is frozen, the camera swings behind it, and the stick
    strafes (`func_8083FD78`). Within 33 deg of the facing he walks forward; pulled straight
    back he back-walks at 1.5x the stick speed (as fast as in OoT); anything else side-steps
    along the stick at 0.9x the stick speed (0.4x for a light push). As in OoT, a side-step from
    standing curves forward slightly while the walk direction turns toward the stick.
- **Ledges.** Running off a ledge still jumps automatically, further at full speed (OoT does
  this without a button).
- **Air control** is almost nil, like OoT: momentum carries the jump.
- **Shield** plants the feet.
- Uphill slopes slow the hero slightly, as in OoT.

All the OoT values are exported on the Player node (Inspector groups "Ground Movement",
"Air & Hops", "Roll", "Sword", "Targeting") with the decomp's units.

## Camera (Ocarina of Time style): `scripts/camera/adventure_camera.gd`

- The rig is a separate top-level node. It follows the hero's **position only**, never his rotation.
- The camera trails the hero inside a distance band, like OoT's normal camera:
  - Walking toward the camera holds it in place until the hero is close, then it backs up.
  - Turning around does **not** swing the camera.
  - Strafing gently orbits it.
- **Shift** smoothly swings the camera behind the hero's current facing in about 0.15–0.35 s.
- **Auto realign:** after **3.0 s** of standing still, the camera eases behind the hero once, over 0.8–1.8 s depending on the angle. Any movement cancels it and resets the idle timer.
- A sphere cast pulls the camera in front of walls and rocks, then eases it back out. Backed
  against a wall, it rises over the hero's head rather than push into the wall, and while its line
  is cut short (a corner, a pillar) it swings toward the clearer side (`obstacle_swing_deg`).
- Doors are solid (`Door` has a body), so the camera never slips out through a doorway.
- **Held shots** (`hold_shot` / `hold_shot_from`, the first unobstructed of a few eyes): the
  arrival shot from inside the room when the hero comes in through a door (`World._arrival_shot`),
  the door shot as he opens one, and OoT's treasure-box camera while a chest opens and he holds
  up what was inside. Each glides back behind him when it ends.
- Lock-on (Q) frames the hero and the target from behind with OoT's battle FOV of 50. A target
  well above him drops the camera to his eye line and lifts the look toward it. Shots home in on
  `Enemy.aim_point()` (Carapax's eye; Gullagog's open mouth while it inhales).
- Holding Q with no target (parallel mode, `Camera_Parallel1`) swings the camera behind the
  hero's facing over 4 OoT frames (0.2 s), then holds it there, at 2.5x his height and FOV 45.
- Any Z-targeting shows OoT's letterbox: 27 of 240 lines top and bottom, sliding in at 10 lines
  per 20 Hz frame. The HUD stays in place and draws over the bars, as in OoT.
- **CLASSIC / MODERN** (pause screen, OPTIONS > CAMERA). CLASSIC is everything above, as in
  OoT. MODERN adds free look in the normal third-person view:
  - the right stick (or the mouse) orbits the camera round the hero and tilts it between
    -10 and 55 degrees, at the CAMERA SPEED setting
  - while it is steered, the swing behind a running hero and the idle realign hold off; 2.5 s
    after it is let go they resume (so standing still, it eases back behind him about 3 s later)
    and the tilt eases home
  - LB / Shift still recenters at once; Z-targeting, first person and talking work as before
- Everything is tunable in the Inspector on `CameraRig`: distance, minimum-distance ratio, pitch, focus height, smoothing, realign speeds and times, idle delay, collision radius, and targeting framing.

## Rendering: true 320 × 240

- The whole game (3D world and HUD) renders into `GameView/GameViewport`, a **320 × 240 SubViewport** in `scenes/main.tscn`.
- `scripts/systems/main_display.gd` enlarges that image with **bilinear** filtering (the soft N64 picture) at the largest **integer** scale that fits, centered with black bars. GRAPHICS > ANTI-ALIASING OFF (or `bilinear` off on the Main node) gives sharp nearest-neighbor pixels. A 16:9 screen gets pillarboxing, never stretching. The default window is 1280 × 960 (4×). Resizing and fullscreen keep 4:3.
- Renderer: **Compatibility (OpenGL 3)**. It is the most predictable choice for this pipeline: per-vertex (Gouraud) lighting, simple depth fog, no post-processing.

## How the early-N64 look is achieved

The look comes from the geometry and materials, not from filters:

- **Characters modeled like the N64 Zelda heroes.** The construction and proportions follow
  the adult hero of Ocarina of Time: every limb is a smooth, low-sided tube (6-10 sides) on its
  own joint, the tubes overlap at the joints so nothing gaps when they bend, normals are
  averaged for soft Gouraud shading (hard edges kept on weapons and armor), vertex colors
  shade the clothes, and faces (eyes, brows, beard, mouth) are painted into a small 64 x 64
  texture wrapped around the head. Proportions: hips at 48% of the height, knees 27%,
  shoulders 73%, big fists and boots, V-shaped chest and a flared tunic hem.
  Sir Gigglebuns IV is about 1,770 triangles including sword and shield, a Cinder Goblin about
  1,450, and the whole test area about 5,300.
- **Vertex colors and per-vertex lighting.** Materials (`assets/materials/`) use vertex colors, per-vertex shading and no specular. There are no PBR maps, normal maps, shadows or post effects.
- **Small textures that stretch, never tile.** UVs span each object once. The whole terrain uses a single 128 × 128 painted texture, with the dirt path and rock areas baked in. Prop textures are 32 × 32. Textures are sampled bilinearly with no mipmaps, like the N64's RDP; the final upscale is bilinear too.
- **Atmosphere.** Dusk vertex-colored sky dome, a low sun, a distant low-poly volcano, linear depth fog, N64-style blob shadows, and choppy torch-flame flicker.
- **Animations** are a few keyframes per pose (idle, walk, run, sidestep, turn, jump, fall, land, roll, side hops, back flip, bonk, two sword slashes, crouched shield and shield hit, put away, hurt, death). The standing Z-target shield is an arm pose layered over the leg animation (`CharacterModel.upper_pose`), like OoT's separate upper-body skeleton. Walk and run playback speed follows OoT's stride timing for the current ground speed.

Character design follows the supplied Sir Gigglebuns IV reference, with adult proportions rather than chibi:
- bald, angular head; full brown beard; brown eyes; stern brows
- dark red short-sleeved tunic with V-neck, brown shoulder strap and belt with brass buckle
- black satchel, brown fingerless gloves, gray trousers, black boots
- broad sword with a brass guard, held with the flat of the blade vertical, and a leather scabbard on the back; octagonal wooden shield with an iron rim

## Project structure

```
project.godot                 Title, input map, physics layers, renderer, autoloads
scenes/
  main.tscn                   320x240 SubViewport + upscaler, HUD, title, pause menu
  areas/<id>.tscn             GENERATED overworld areas (terrain, sky, props, exits, hero, camera)
  test_area.tscn              Debug sandbox: lighting, fog, player, camera rig, three enemies
  player/player.tscn          Sir Gigglebuns IV (CharacterBody3D)
  enemies/basic_enemy.tscn    Cinder Goblin (CharacterBody3D)
  enemies/<kind>.tscn         GENERATED creatures (tools/gen_creatures.gd, gen_shrine_creatures.gd)
  environment/test_environment.tscn   GENERATED terrain, ruin, props, sky
  ui/                         hud / title_screen / pause_menu
scripts/
  player/       player_controller.gd (movement, states), player_combat.gd (sword, shield)
  camera/       adventure_camera.gd
  enemies/      enemy.gd (what every creature shares), enemy_controller.gd (Cinder Goblin),
                tektite, keese, snapper, leever, octorok (+ rock), stalfos, shellblade,
                tide_knight, carapax (+ bubble, enemy_part)
  items/        arrow, collectible (rupees, hearts...), drops, shrub, pot, lift_rock, throwable
                (anything carried or thrown), signpost, boomerang
  dungeon/      dungeon_room (respawn, shutters, clear flags), shutter, chest, get_item,
                locked_door, crystal_switch, floor_switch, flag_mover (bars, bridges),
                heart_container, blue_warp
  combat/       hitbox.gd, hurtbox.gd, hit_info.gd, health_component.gd
  systems/      game_manager.gd, sfx.gd and world.gd (autoloads; World loads areas and
                runs the loading screens), world_data.gd (area list, world map layout),
                area_exit.gd (loading zones), void_zone.gd (deep water), surface.gd
                (footstep surfaces), fragments.gd (debris bursts), character_model.gd,
                main_display.gd, blob_shadow.gd, sky_dome.gd, torch_flicker.gd
  ui/           hud.gd, minimap.gd, pause_menu.gd (OoT pause box), title_screen.gd,
                pixel_font.gd (built-in 5x7 font)
assets/
  models/       GENERATED character scenes (rig + AnimationPlayer) and small meshes
  materials/    GENERATED shared N64-style materials
  textures/     GENERATED small PNG textures; world/ holds each area's painted ground,
                sky panorama, map and minimap
  audio/        GENERATED placeholder .wav sound effects
tools/          Procedural asset generator (see below)
tests/          Automated tests and screenshot tools (see tests/README.md)
```

Collision layers: 1 world, 2 player, 3 enemy, 4 player hurtbox, 5 enemy hurtbox, 6 player attack, 7 enemy attack.

### Generated assets

All models, animations, textures, materials, sounds and the test environment are built by
original code in `tools/`. Nothing is extracted from any existing game. To regenerate them after
editing the generator:

```
powershell -ExecutionPolicy Bypass -File tools\build_assets.ps1 -Godot "C:\path\to\Godot_v4.7.2-stable_win64.exe"
```

The script runs the generator in two passes with an import in between. Hand edits to generated
files are overwritten by the next run, so change the generator instead:
- `gen_characters.gd`: models and animations (`gen_media.gd` paints the face textures)
- `gen_environment.gd` and `level_layout.gd`: the test area
- The overworld:
  - `gen_world.gd`
  - `world/world_kit.gd`: terrain, sky, props, buildings, exits
  - `world/regions/*.gd`: one file per area, with its shape, ground painting, mood and layout
  - To rebuild only some areas, set the environment variable `G64_REGIONS` (for example `G64_REGIONS=field,village`).
- `gen_media.gd`: textures and the original sounds; `gen_sounds.gd`: footsteps, ambience and
  the newer sound effects and jingles
- `gen_items.gd`: rupees, hearts, keys, the boomerang, pots, grass, signs, chests, doors, switches
- `gen_creatures.gd` and `gen_shrine_creatures.gd`: the creatures and their enemy scenes
- `check_scripts.gd`: loads every region script and reports parse errors

### Replacing sounds

Drop a `.wav` with the same name into `assets/audio/`, for example `sword_swing`, `rupee`,
`fanfare_item`, `chest_open`, `boss_roar`, a footstep such as `step_grass_0` / `step_grass_1`,
or an ambience loop such as `amb_field` (see `tools/gen_sounds.gd` for every name). Missing
files are skipped, so the game runs without audio.

Music (`assets/music/`, see its README.txt): `title_theme` on the title screen, `mirror_lake` at
Mirror Lake, `inside_house` indoors, `lake_shrine` in the Lake Shrine and `boss_battle` during the
fight with Carapax.

## Gameplay summary

- **Hero:** 3 hearts to start (6 half-hearts), 22 at most: 12 heart containers and 28 Pieces of Heart.
  - Moves like Link in Ocarina of Time (see Movement above).
  - Hits give knockback and about 1 s of blinking invulnerability.
  - Death returns him to the spawn point. Falling off the east cliff costs one heart and respawns him.
- **Sword:** forehand slash with an optional backhand follow-up. The hitbox is active for a short window and hits each enemy at most once per swing.
- **Shield:** blocks attacks within ±75° of the facing direction; attacks from behind get through. A blocked goblin recoils and is stunned for about 1 s.
- **Cinder Goblins** (3 HP each) cycle through idle, patrol, alert, chase, wind-up, smash, recover, hurt, stunned, return and dead states.
  - They detect the hero by range, view cone and line of sight.
  - At most two may attack at once.
  - Each attack is followed by a recovery period.
  - Dead goblins drop out of combat and sink away.

## Known issues and limitations

- No navigation mesh: enemies steer directly, with simple wall sidestepping. That is enough for this open map, but they can get briefly hung up on scenery.
- Backing away while locked on or back-walking in parallel mode plays the walk cycle in reverse (there is no separate back-walk animation).
- The Lake Shrine and the Southern Tower are open; the other dungeon doors and caves are sealed.
- A loaded game starts at the entrance of the area it was saved in (OoT restarts at Link's
  house or the dungeon entrance).
- Biscuit stays behind when the hero leaves the open fields; call her again with the Sugar Cube.
- The Bun Pieces on the quest page are placeholders.
- OoT lets the stick tilt the crouched shield; here it stays facing forward.
- Putting the sword away plants the feet for half a second (OoT does it on the upper body while walking).
- OoT's 3-point bilinear filter is approximated by standard 4-tap bilinear filtering.
- Defeated goblins do not respawn. Use **Pause → Restart Area** to reset the encounter.
- The audio is simple synthesized placeholders.
- Feel and tuning were verified by automated tests and screenshots, not by extended hands-on play or with a physical controller. Expect to adjust speeds and timings in the Inspector.
