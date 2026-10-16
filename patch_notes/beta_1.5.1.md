# Beta 1.5.1 — The Long Way Round

A fix patch after a full sequence-break sweep of the whole game, Chapter I to the end. Every gate was checked again, and the geometry audit now climbs, wades and drops the way Gigglebuns does, over whole regions at once. Eight ways to skip ahead were found and closed.

## Fixes
- **No walking round the sandstorm.** The wall of sand over the desert's old east road was narrower than the road and its banks. From a brand-new file you could walk up the south bank, round its end, and into the Forest of the Dead and the Batela Fells, two chapters early. The storm now fills the road from bank to bank until the Order's map shows the way.
- **No wading round to Black Water Ridge.** The thicket on the road west out of the marsh could be waded round at its south end, through the shallow water, which put the Chapter V Ridge within reach in Chapter I. The thicket now reaches across the water, and the road is sealed again further in, where it narrows between the rocks. Both go when the starlight parts the black water.
- **The brambles over the Dark Forest road** now reach up the banks too, the same way.
- **The pass to Cinderhold waits for the Hollow King.** The Questlord's Gauntlets are won halfway through the Barrow of Kings, so you could leave and drag the great stone on the cliffs aside before the Hollow King had told you where Firebuns went. The stone now won't move until the kings are at rest.
- **Westmarch Fortress waits for the Siege of Haven.** In Chapter IV the fortress gate opened as soon as the war began. You could walk straight in, skipping Captain Rowena, the three war camps and the defense of Haven, and the journal then stayed stuck on the camps. The gate now stays barred until Haven has held through the night.
- **No climbing into the Sapphire Sanctum early.** The stone mouth of the crypt in the Batela Fells had walls low enough to jump-grab. From the top you could drop in behind Elder Maud's iron gate and go down before her confession. The walls can no longer be climbed, and the crypt door itself now waits for Maud as well.
- **No more perching on thin wall ends.** Where one thin wall met another in a T, as along a row of cells, Gigglebuns could jump at the end, catch the top of the wall behind it and walk the wall tops past bars. This worked in the Sapphire Sanctum's cells and Westmarch's cells. A ledge must now be as wide as he is before he will climb onto it. Proper ledges, crates and blocks climb exactly as before.
- **Cinder Vault and Ridge Keep.** The walls beside the thorns over each Compass, and the ice walls of the Cinder Vault's frost hall, could be climbed over instead of burning or melting a way through with the Ember Rod. They are now too sheer to climb.
- **Rowena when the camps come first.** If you break the war camps before you find Rowena, she now thanks you for them instead of asking you to break them. The siege's opening scene also counts as meeting her, so the journal's first Chapter IV step can no longer stay open.

## Nothing lost for good
Some places close for ever as the story moves on: the burning Citadel once Firebuns is sealed, the war-time field and refuge at the peace, and the castle while the town is rebuilt. Anything left behind in them now turns up again after the peace:
- **Captain Rowena** (at the rebuilt town's gate, or later in the Knights' Yard) tells you the rest of the lost garrison made their own way home. She hands over every reward you hadn't collected, a Heart Shard among them, and the treasure chart scrap from the goblin camps' loot.
- **Pink** has things the salvage crews dug out of the old castle: the Long Grapple from the Citadel's library, the chart scrap from the Citadel's vault, and the Heart Shard from behind the castle's oubliette wall.
- **Posy**: if you were looking for Pepper but never brought him home, he found his own way back. She still thanks you for looking.

Each is given only if you missed it, and only once.

## Checked and still sound
- Every locked door in all sixteen dungeons: none can be walked round.
- A fill over every region, from where you arrive, on a fresh file and with the story's flags: every way out that should be shut is shut, and every one opens again when its moment comes.
- Every story gate and the item behind it: the castle's cistern pit (Bloom Rod), the frozen falls (Iron Mallet), the Sun Trial's stones (Bun Bracers), the great stones (Questlord's Gauntlets), the sandstorm, the brambles, the crypt, the chapel, the black water, the chains and the Rift's mouth.
- Biscuit can't jump any story barrier, the Grapple Hook only bites on its wooden targets, and bombs can't break the ice over Frostpeak Hollow.
- Saves, CONTINUE after a game over, waystones and skipped cutscenes all put you back in the right version of every place.

## Under the hood
- The geometry audit (`tests/geometry_audit.tscn`) has new modes:
  - `--climb`: the fill also climbs and drops the way the hero does.
  - `--only=selftest`: checks the climbing fill on test walls.
  - `--only=reach`: point to point, "can he get from here to there?".
  - `--only=gates`: one climbing fill over a whole region, listing each way out it reaches.
  - `--only=walk`: steers the real hero along a path.
- New tests: test_no_perch_on_thin_wall_t, test_westmarch_waits_for_siege, test_crypt_waits_for_confession, test_rowena_met_after_camps, test_sandstorm_not_walked_round, test_marsh_thicket_not_waded_round, test_catch_ups_after_peace. test_great_stone_pull now checks that the cliffs stone waits for the Hollow King.
