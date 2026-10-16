# The Satchel (alpha 1.6.0): open questions and suggestions

Written 2026-10-12 after the 1.6.0 item update. See also `design/item_plan.md` §1 and `patch_notes/alpha_1.6.0.md`.

## What was built (quick recap)

- SELECT ITEM has 20 slots in 4 sections, one per row:
  - ARMS: Bow, Sun Arrows, Frost Arrows, Bombs, Puff Nuts
  - TOOLS: Boomerang, Hookshot, Bloom Rod, Iron Mallet, Fishing Rod
  - MAGIC: Lantern, Mira's Looking Glass, Alan's Harvest, Aphiel's Gale, Serielye's Ruin
  - PACK: Bottle x4, Sugar Cube
- Cut from the plan: Burrow Mitts, Hopper Bombs, Honey Buns (as a carried item; Idrith's buns are still sold in the shop), Trade Item.
- OoT-style pause art on every page, a magic meter (48 units, from the first magic item), magic jars, and all 16 items working.
- Item sources in the game now:
  - Puff Nuts: Marigold's shop
  - Lantern: Ottilie, on your second library visit
  - Fishing Rod: Mira, after the big fish
  - Looking Glass: Mira at night, after the moonlit chest
- The Looking Glass reveals one invisible chest on Mirror Lake's second islet (a Piece of Heart).
- Screenshots: `_giggle64_work/tmp/u16/cap/` (`01_select_item.png` is the new page).

## Questions

1. **Where should Sun Arrows, Frost Arrows, the Iron Mallet and the three blessings come from?**
   Right now they come only from the debug menu (F1 > ITEMS).
   - The plan's idea: three hidden **Goddess Springs**, one per goddess (Alan, Aphiel, Serielye), each giving its blessing. That touches the lore, so it needs your OK.
   - Sun Arrows: maybe a spring in the Desert of Ladhellin.
   - Frost Arrows: maybe a Frostpeak / Skyreach side cave.
   - Iron Mallet: maybe a Chapter II dungeon (after the lost final battle).
2. **The double magic meter:** the code supports 96 units, but nothing gives it yet. Should it come from a Goddess Spring or a story beat?
3. **Mira's Looking Glass backstory:** her line says the lake gave it to her "one full-moon night". Change it if you have a different backstory for Mira.

## Suggestions

- **More Looking Glass secrets:** fake walls and hidden platforms in the towers, and more invisible chests. So far there's only the Mirror Lake chest.
- **Iron Mallet targets:** rusted floor switches and stakes to hammer down (OoT's Megaton Hammer puzzles). The code already calls `mallet_hit()` on anything in the `mallet_targets` group.
- **Fish in a bottle:** let a caught fish go into an empty bottle, as the original plan had it.
- **EQUIPMENT page:** give it the same tray styling as SELECT ITEM, plus the planned Tunics row and upgrades column (`design/item_plan.md` §3–4).

## Status (beta 1.7.0, 2026-10-16)

- Questions 1-3 were settled by the Goddess Springs update (alpha 1.7.0) and the Beta's item sources.
- **Looking Glass secrets:** besides the Mirror Lake chest, there are now:
  - false-wall alcoves in the Southern, Ladhellin and Skyreach towers;
  - false walls in Frostpeak Hollow and the Sapphire Sanctum;
  - hidden chests in the Lake Shrine's coral hall (Purple Coin) and the Castle's wine cellar (Gold Coin).
- **Iron Mallet targets:** besides Frostpeak Hollow, the Sanctum and the Citadel, three-peg puzzles now raise a Purple Coin chest in the Southern Tower (den), Ladhellin Tower (shrine) and Bog Tower (snare room).
- Fish in a bottle and the EQUIPMENT tray were built earlier (alpha 1.7.0 / beta 1.0.0).
