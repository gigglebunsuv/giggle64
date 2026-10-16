# Giggle 64 — Item Plan

**Status:** SELECT ITEM is built (alpha 1.6.0, see §1). The EQUIPMENT page got SELECT ITEM's trays and an UPGRADE tray in 1.7.0; the Tunics row (§3) is still plan only.
Written for alpha 1.5.0 (2026-10-12). Names, sources and story hooks are proposals; change anything.

Ground rules this plan keeps to:
- No musical instrument items (rejected).
- The Gauntlet of Fire stays a story object, never an item. No fire regions or gauntlet gates.
- Items are used from **X / Y** (OoT's C-Left / C-Right); RB stays first-person look.
- Everything mirrors OoT behavior where an OoT equivalent exists (z_player.c, kaleido).
- New items need: a mesh in a `tools/gen_*_items.gd` generator, an icon in `tools/render_icons.gd`, a `GetItem.ITEMS` entry, a `Progress.ITEMS` entry, and a test.

---

## 1. SELECT ITEM — final (built in alpha 1.6.0)

20 slots (`Progress.ITEM_GRID`, 5 x 4), one section per row (`Progress.ITEM_SECTIONS`):

```
 ARMS   BOW        SUN ARROWS   FROST ARROWS  BOMBS          PUFF NUTS
 TOOLS  BOOMERANG  HOOKSHOT*    BLOOM ROD     IRON MALLET    FISHING ROD
 MAGIC  LANTERN    LOOKING GLASS ALAN'S HARVEST APHIEL'S GALE SERIELYE'S RUIN
 PACK   BOTTLE     BOTTLE       BOTTLE        BOTTLE    |    SUGAR CUBE
```
\* The Hookshot can still upgrade in place to a Longshot later.

All 16 items and the 4 bottles work. Item behavior lives in `scripts/player/player_items.gd`
(PlayerItems), with the arrow kinds in `arrow.gd` and the daze/freeze in `enemy.gd`.

**Cut** (2026-10-12): Burrow Mitts, Hopper Bombs, Honey Buns (carried), Trade Item.

### Where they come from

| Item | Source | Status |
|---|---|---|
| Puff Nuts | Marigold's shop (30), grass/enemy drops | built |
| Lantern | Ottilie, second library visit | built |
| Fishing Rod | Mira, after the 10 lb fish prize | built |
| Mira's Looking Glass | Mira at night, after the moonlit chest | built |
| Sun Arrows | ? (Goddess Spring, Desert of Ladhellin?) | **debug menu only** |
| Frost Arrows | ? (Frostpeak / Skyreach side cave?) | **debug menu only** |
| Iron Mallet | ? (Chapter II dungeon?) | **debug menu only** |
| Alan's Harvest | Alan's Spring (Hidden Forest, east cliff, bomb wall) | built (1.7.0) |
| Aphiel's Gale | Aphiel's Spring (Northeastern Cliffs, third tier) | built (1.7.0) |
| Serielye's Ruin | Serielye's Spring (Desert, rock pile under the arch) | built (1.7.0) |
| Double magic | Spring of Lothelye (West Marshlands, Hookshot islet) | built (1.7.0) |
| Double defense | Spring of Lothelye (Southern Fields, NE hills, bomb wall) | built (1.7.0) |

Magic meter: comes with the first magic item (48 units), shown in blue; Lothelye's marsh spring doubles it (96).
Looking Glass secrets so far: one invisible chest on Mirror Lake's second islet (Piece of Heart).

---

## 3. EQUIPMENT — rows and upgrades

Today the page has 3 rows (swords 4, shields 3, boots 2). The plan is OoT's **4 × 4 grid plus an upgrade column**.

| Row | Slot 1 | Slot 2 | Slot 3 | Slot 4 |
|---|---|---|---|---|
| **Swords** | Squire's Sword ✔ | Red Sword ✔ | Magical Sword ✔ | Bun Sword ✔ |
| **Shields** | Wooden Shield ✔ | Iron Shield ✔ | Mirror Shield ✔ | *Questlord's Shield* (planned: Aladriel's old shield; blocks magic bolts and fire breath) |
| **Tunics** *(new row)* | Haven Tunic (default) | *Tide Tunic* (breathe under water) | *Frost Mantle* (no chill at Frostpeak) | *Shade Cloak* (planned: unseen by sentries and shades for a moment) |
| **Boots** | Leather Boots ✔ | Wind Boots ✔ | *Anchor Boots* (sink, walk on lake and river beds, stand fast in strong winds) | *Sand Treads* (cross quicksand without sinking) |

**Upgrades** (no slot to equip; shown in a column, each with its level):

| Upgrade | Levels | Sources |
|---|---|---|
| Quiver | 30 → 40 ✔ → 50 | Marigold ✔, archery prize |
| Bomb Bag | 20 ✔ → 30 → 40 | Marigold ✔, Hopper Bomb stall |
| Puff Nut Pouch | 20 → 30 → 40 | Snapper drops, Forest prize |
| Wallet | 99 → 200 ✔ → 500 | Clover ✔, a Castle Town game |
| Bracers (strength) | none → Bun Bracers (lift heavy rocks) → Questlord's Gauntlets (pull pillars) | Chapter II |
| Diving Scale | 2 m dive ✔ → Silver Scale (deeper) → Gold Scale | Fishing prizes |
| Magic Meter | none → single → double | First Goddess Spring → a later one |

The tunic row needs a new Progress list (`tunics`, `tunic`) and model color swaps in `CharacterModel.set_gear`.
The upgrade column only reads existing Progress values (`arrows_max`, `bombs_max`, `wallet`, …) plus three new ones (bracers, scale, magic).

---

## 4. The new EQUIPMENT page (layout and style)

The page stays a 256 × 176 page on the pause drum (`pause_menu.gd`, `_draw_equipment`), with the same colors: the navy panel, gold edge, gold title and round slots used on every page.

```
+------------------------------------------------------------------+
|                          EQUIPMENT                               |  title bar (gold on brown)
+--------+-------------------+-------------------------------------+
| UPGRADE|                   |  SWORDS   ( ) ( ) ( ) ( )           |
|  [Q] 40|    hero portrait  |  SHIELDS  ( ) ( ) ( ) ( )           |
|  [B] 20|    (turning, in   |  TUNICS   ( ) ( ) ( ) ( )           |
|  [N] 30|     his gear)     |  BOOTS    ( ) ( ) ( ) ( )           |
|  [$]200|                   |                                     |
|  [S] 2 |  SIR GIGGLEBUNS IV|  POWER 4 . BEAM AT FULL HEALTH       |  stat line for the cursor's row
|  [M] = |                   |                                     |
+--------+-------------------+-------------------------------------+
```

Measurements (page pixels):
- **Upgrade column**: x 6–40. Seven 16 px icons stacked every 20 px from y 24, with the level in small digits to the right (gold when maxed, like the ammo counter).
- **Portrait**: x 44–112, the same 80 × 120 turning hero shown smaller, with his name under it. Tunics change his colors live.
- **Gear grid**: 4 × 4 round slots (radius 11) at x 136 + col × 28, y 34 + row × 30. Row labels in small gray caps to the left of each row. The equipped piece keeps its gold square frame. Empty slots stay dark and have no name.
- **Stat line** (y 156): shows something for every row, not just the sword:
  - sword: power and beam
  - shield: blocks heavy blows / reflects
  - tunic: its effect
  - boots: their effect
- **Name panel** (under the drum, as now): the name of what the cursor is on. In the upgrade column it shows the upgrade and its level ("QUIVER — 40 ARROWS").
- **Cursor**: up and down move between rows. Right from the end of a row flips to the next page, and left from the upgrade column flips back. This keeps today's flipping behavior.

The SELECT ITEM page keeps its 6 × 4 grid. Once rows 2–3 fill up, two small touches help:
- a thin divider above the bottle row;
- a "magic" pip on items that use magic (Sun and Frost Arrows, the Looking Glass, the three blessings).

The HUD gets a **magic bar** under the hearts (OoT's green bar) once the meter exists.

---

## 5. Systems the plan needs (build these before the items that use them)

1. **Magic meter**: Progress `magic`/`magic_max`, the HUD bar, green magic jars as drops, and refills at Goddess Springs. Used by the Sun and Frost Arrows, the Looking Glass and the blessings.
2. **Arrow types**: the bow cycles normal / sun / frost (OoT puts each arrow type on its own C button; here the arrow items can each go on X or Y and fire from the bow).
3. **Tunic row + color swap**: in `Equipment`, `Progress` and `CharacterModel`.
4. **Underwater walking**: the Anchor Boots in the swim code (OoT's iron boots, `Player_Action_Swim` with `IRON_BOOTS`).
5. **Dig patches and soft walls**: world kit helpers for the Burrow Mitts.
6. **Hidden-object layer**: things only drawn through the Looking Glass (a group the lens toggles).
7. **Trade chain state**: one Progress string with the current trade item.

---

## 6. Open slots and loose ends to decide later

- **Fourth bottle**: a reward for the trading chain, or for finding every Piece of Heart.
- **Trade chain** (proposal): Clover's lucky horseshoe → Pink (re-forges it) → Ottilie (wants the horseshoe nail for her press) → Marigold → Mira → back to Pink, who forges the **Questlord's Shield**.
- **Goddess Springs**: built in 1.7.0 (three goddess springs plus two Springs of Lothelye, see §1).
- **Chapter II**: the Iron Mallet, Bracers and Longshot are meant for the dungeons after the lost final battle (ask before planning that story).
- **Questlord's Gauntlets**: named for the Questlords, *not* a gauntlet of fire. Rename if it reads too close to the Gauntlet of Fire.

## 7. Suggested build order

1. The new EQUIPMENT page layout with the tunic row and upgrade column, filled with what exists (empty slots dark).
2. Magic meter + Goddess Springs + the three blessings.
3. Lantern and Looking Glass (they fit the day/night update).
4. Sun / Frost Arrows.
5. Tunics and boots (Tide Tunic, Anchor Boots, Sand Treads, Frost Mantle).
6. Puff Nuts, Honey Buns, Hopper Bombs, Fishing Rod, the trade chain.
7. Chapter II tools (Iron Mallet, Burrow Mitts, Bracers, Longshot), with their dungeons.
