# Beta 1.3.2 — The Sharpened Blade

A big fix-up patch from the Beta 1.3.1 bug list, with a harder fight all round, a pink Bun Sword and music for the mini-bosses.

## Harder fights
- **Enemies scale with the story.** Once the Bun Sword is drawn, every creature in Haven is permanently two ranks tougher (more health, harder blows, a little quicker and keener-eyed). The open regions grow tougher with each chapter, and from Chapter III's dungeons on (the Sapphire Sanctum and every one after) the creatures are a further rank harder. The ranks now go up to *Mythic*.
- **Bosses take far more blows**, set for the sword you'll have by then (Gullagog three times its old health, Magmaw four and a half...).
- **Firebuns III is a real fight.** All three battles are counted in blows landed, not health, so a stronger sword no longer cuts them short: 16 blows in the throne room, 14 in the duel at Batela Keep (or 80 seconds), 16 on the Citadel roof. Halfway through he stops playing: he stalks faster, chains a second cut after the first, lunges across the floor in a rush of flame at a hero who keeps his distance, throws five fireballs instead of three and sends two rings of fire. He also hits harder in the duel.
- **Bosses show their attacks and weak points.** Gullagog marks where it will land (a ring as wide as its shockwave, then the shockwave itself), shows the line its tongue will lash, and its gaping throat glows while it inhales (the lock-on moves onto it). Its belly glows while it lies on its back. Carapax marks its charge's path and the ground under its raised claw.
- **Carapax's lock-on is its eye**, so the Boomerang, lock oned arrows and the Grapple Hook all fly straight at it. The eye glows whenever a hit would throw the crab over, and its target is a little bigger.
- **Knight mini-bosses** (the Tide Knight and its kin) no longer hit you from behind with their sweep: it's an arc in front of them, and they turn to face you as they wind it up.

## Music
- **Mini-boss music.** Mini-bosses now play their own theme (`miniboss`; the MIDI is written: C minor, built on the opening of the main motif). Until the .ogg is in place they use the boss theme instead of going silent.
- Mini-bosses no longer **stop the music** when they fall: the dungeon's own music comes back.
- Boss music no longer **keeps playing after a boss is beaten**: the room falls silent, as in Ocarina of Time.
- **The Firebuns-returns scene is scored to its music.** Every moment lands on its place in *firebuns_returns.mid*: the crack creeps in with the low tremolo, the ice shatters on the orchestra hit, his Gauntlet blazes on the first beat of his theme, Mara rises with her motif, and Haven shakes on the timpani roll. The text boxes run on by themselves inside each section.

## Camera, doors and chests
- **No more black square at dungeon entrances.** Doors are solid now, as in Ocarina of Time, so the camera can't slip out through a doorway behind you.
- **Walking in through a door** (dungeons, houses) has a short arrival shot: the camera waits inside and watches you step in, then glides round behind you.
- **Opening a door** has a door shot, and **opening a chest** has Ocarina of Time's treasure camera: it swings round in front of you while the lid comes up and you hold up what's inside, then glides back.
- **The camera fights walls less.** Backed against a wall, it rises over your head instead of pushing into it, and when a corner or pillar cuts it off it swings round toward the open side.
- **Locking on to something high up** (a flying foe, an archer on a ledge) drops the camera to your eye line and tilts the view up to keep it in frame.

## First person
- The **sword goes back in its sheath** when you look or aim in first person, so it no longer hangs in front of the view.
- Aiming from behind the head now shows **only your arms and what they hold**: no cape (Himeko's regalia), no shield on the arm.
- Your upper body **follows the aim up and down**, the bow **kicks back** a little when you loose an arrow, and swapping items in first person **lowers one and raises the other**.

## The world
- **The Sun Trial** really is sealed until both great stones are lifted (you could walk round them).
- **Cinderhold**: the east pass now narrows to a cleft of rock that the great stone fills (it was a ten-meter-wide pass with a small stone in the middle).
- **Walk-arounds fixed**: the cells and the quartermaster's grille in Westmarch Fortress, the ore-room thorns in the Cinder Vault, the chapel ward in the Citadel, and the brambles over the Dark Forest track (now across the whole track).
- **Exits and caves kept clear**: trees, rocks and logs no longer land in the way of a loading zone, a cave mouth or a door (the Forest of the Dead's and the Dark Forest's ways out were half-blocked).
- **Low stones and steps are walked up**: anything lower than a ledge (like the Bog Tower's stepping stones) no longer stops you dead.
- **The castle armory's racks** are proper racks now, against the walls, with uprights and spears, and solid.
- **Creatures never start inside furniture** (a Sapphire Mage stood in the guard room's table).
- **A only reaches things on your own floor**, never a door or chest a storey above or below, and not through a wall.
- **Enemies in passages** (not in a room) must see you to chase you: no more hunting through walls in the Burning Citadel. The Citadel's Rust Knight is an ordinary knight there, with no name card.
- **Arrival scenes** (the Batela Fells, Cinderhold) play as you arrive, instead of only after you walk back out and in.
- **The bombable walls and boulders** look the part: a pale, uneven cracked wall with a dark burst of fissures and crumbs at its foot, and a dull brown boulder split all round with dark cracks.
- Every door, exit and blocker in Haven is checked by a new automatic **geometry audit** (`tests/geometry_audit.tscn`).

## Story scenes
- Aladriel and Idrith **hold their weapons by the grip** (they held them by the blade), and Aladriel no longer **sits down** in the middle of the throne-room rescue.
- Questlords who are standing **talk standing** (they sat down whenever you spoke to them).

## Hearts, items and menus
- **Three hearts to start** (was five). **28 Heart Shards** (was 32): with the twelve Heart Vessels, that's **22 hearts** at the end of the game. The four pieces taken out (the lake bed, and the caves behind the heavy rock in the fields, the forest's bombed cave and Frostpeak's) now hold coins.
- The hearts sit in **two rows of eleven**, and the **double magic meter** is as long as a row.
- **The Ember Rod** (it costs magic) moves to the **MAGIC** row; the **Lantern** moves to **TOOLS**.
- **The Bun Sword turns pink** when it wakes in the Temple of Bun: in your hand, on the HUD and on the EQUIPMENT page.
- **Menus and the stick**: a light touch no longer moves the cursor; it takes a firm push, along the stronger axis (pause screen, file select, waystones, text-box choices, the debug menu).
- The **Knight's Tabard** fits on the EQUIPMENT page, and the **SELECT ITEM** icons in the last column stay inside their tray.

## Notes
- **Fall damage** follows Ocarina of Time exactly (z_player.c): a fall of 400 units (12 m) or more costs half a heart, 800 units (24 m) a heart; held forward on landing from more than 80 units, you roll out of it, and below 800 the roll saves you the damage. locking on stops the roll. Haven's tallest single drops (the Northeastern Cliffs' tiers, 9.6–11 m) are just under the line.
