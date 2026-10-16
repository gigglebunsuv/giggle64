# Giggle 64 — Alpha 1.5.0: Night Falls on Haven

Haven now has day and night, and the sound has had a full overhaul. Also new:
bottles and fairies, a SOUND options page, skippable cutscenes, and a Mire
Knight that hides in the bog.

## Day and night

- **The clock runs.** Out in the open (fields, towns, the lake) the day
  passes: a full day is about 18 minutes of play, and the night goes by a
  little faster, as in Ocarina of Time. Time stands still indoors, in
  dungeons, while paused and during scenes. The hour is saved with your game.
- **Dusk, night and dawn.** Each area's own light is its noon. In the evening
  it warms to orange, then turns deep blue at night: the sky darkens, stars
  and a moon come out, and the sun becomes a dim, cool moonlight. Dawn
  brings a pink morning.
- **Night sounds.** Crickets and the odd owl rise under each area's own
  ambience after dark. A rooster crows at dawn in the village and on the
  farm, and a far-off howl marks nightfall out in the fields.
- **Quiet nights.** Out in the open there is no music after dark, only the
  ambience and the night sounds. The music fades out at dusk and comes back
  at dawn.
- **Shops keep hours.** Marigold's Goods is open 6 AM to 9 PM and the library
  7 AM to 9 PM. At night their doors are shut, with a note.
- **Clover goes home** at night (the jumping course waits for morning).
- **The dead walk at night.** In Bunsriel Fields, the South Road and the
  Southern Fields, Skeletons claw up out of the ground after dark and sink back
  at dawn.
- **Fairies** drift over a few flower patches at night.
- **The moonlit chest.** Something shines on an islet of Mirror Lake, but only
  after dark...
- **Rest at Mira's.** Talk to Mira and she offers her fireside: rest until
  nightfall, or until morning (with a full heal).
- The **map page** shows the time, with a sun or a moon.

## Sound overhaul

- **Footsteps fixed.** They were far too loud, especially on stone: every
  sound was played at the same loudness, and quiet sounds were only half as
  quiet as intended. Now:
  - steps are quiet when you creep and clear when you run;
  - every step varies a little at random;
  - each surface has its own level (stone, wood and ice sit lower);
  - the stone step was remade as a soft heel thud and scuff, not a sharp
    click;
  - landings are as loud as the fall was high.
- **Squelchy boots.** For a few seconds after a swim, your steps squelch.
- **A real mix.** Every sound now has its own level. Small and frequent
  sounds (cursor ticks, text, pickups, swishes) sit under the big moments.
- **Audio buses.** Music, Ambience, Sound FX, Footsteps and Text Sounds each
  play on their own channel.
- **Music ducks under text boxes**, so dialogue is easier to hear.
- **Pause muffle.** Music and ambience sound muffled behind the pause screen,
  as if from the next room. You can turn this off.

## New: OPTIONS > SOUND

A new page on the pause screen's OPTIONS list:
- **Volume sliders** (0–10, left and right to change) for Master, Music,
  Sound FX, Footsteps, Ambience and Text Sounds. Each one plays a sample as
  you move it.
- **Output**: Stereo or Mono.
- **Pause muffle**: on or off.

Your choices are saved.

## New: bottles and fairies

- **Bottles** go on X or Y. You can carry up to four, along the bottom row of
  SELECT ITEM:
  - **Empty**: swing it at a fairy to catch her.
  - **Fairy**: let her out to heal 8 hearts. Keep her, and she brings you
    back with 8 hearts when you fall.
  - **Milk**: two drinks of 5 hearts each.
  - **Red Potion**: fills every heart.
- Where to find them:
  - **Marigold** sells an Empty Bottle (120) and Red Potions (40, poured into
    an empty bottle).
  - **Clover** gives you a Bottle of Milk once Biscuit is yours, and refills
    empty bottles with milk for 15.
  - One more is in the moonlit chest.
- **Fairies** heal 8 hearts if you walk into them.

## Cutscenes

- **Skip scenes you've seen.** Once you have watched a story scene to the end,
  "START: SKIP" shows in the letterbox the next time it plays. The scene runs
  through at speed behind a black screen, so everything it sets up still
  happens. Watched scenes are remembered across save files.

## Mini-bosses

- **Name cards.** The Tide Knight, Rust Knight, Sentinel, Mire Knight and
  Sapphire Warden now show their name the first time you meet them, like the
  bosses do.
- **The Mire Knight burrows.** Once its armor is off, the Bog Tower's
  mini-boss sinks into the bog. A trail of bubbles hunts you across the
  floor, stops and boils, and the knight bursts up out of the muck. Step away
  when the bubbles boil, then strike while it hauls itself free.

## Debug menu

- **SCENES tab**: play any story scene (the Legend, Castle Town falling, the
  rescue, the throne room, the last fight and ending). Each starts from a
  clean state, and your game is put back exactly as it was afterward. The
  ending offers no save from here.
- **SOUND tab**: play any sound by name, on its own bus.
- **STATE tab**: set the time of day, stop the clock, and forget which scenes
  have been watched.

## Fixed

- The debug menu printed an error every frame while it was open.

## Planned

- `design/item_plan.md` lays out the rest of the items: the full 24-slot
  SELECT ITEM grid, the new EQUIPMENT page (a tunic row and an upgrade
  column), and the systems those items need. None of those items are built
  yet.
