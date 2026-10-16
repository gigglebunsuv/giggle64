# Saga V "The Fall": plan for the next game (not built)

Written 2026-10-16, after beta 1.7.0. This is a starting point for a sequel's masterplan, built from Saga V of *The Complete Story of the Kingdom of Bunsriel* and the hook at the end of Giggle 64 (riders in the Batela Fells, a scythe catching the light). Nothing is decided. Every choice below is yours.

## The lore it follows (Saga V, "The End of the Kingdom of Bunsriel")

- **Camue, the Lord of Death**, gathers an army of Death Knights, the Dark Fyrd of Batela, in the Batela Fells and marches on a prosperous Bunsriel.
- **Sir Gigglebuns V**, the most promising hero, was **banished** years before. He sets out to reclaim his birthright.
- He crosses the **Dark Forest** to the ruined **Temple of Bun** and finds the Bun Sword. It glows only dimly, not at full power.
- Bunsriel is already in ruins when he arrives. He fights the Death Knights, is **captured** and held in the castle's dungeons, with the sword nearby but out of reach.
- He **calls on his ancestors**, and a dormant power wakes. The walls crumble, he takes the sword back and meets Camue, a towering figure in dark armor with a scythe.
- They duel from the dungeon to the courtyard. Gigglebuns V nearly wins, but **Camue strikes him down**. The kingdom falls, and its spirit lives on in the people (leading into Saga VI, "Nightfall").

## A shape for the game

**Working titles** (pick one or name it yourself): *Giggle 64: The Fall of Bunsriel*, *Giggle 64: Lord of Death*, *Giggle 64: The Last Knight*.

**Chapters** (one per update, as with the masterplan):

| Chapter | Beats | Places | New mechanic |
|---|---|---|---|
| I. The Exile | Gigglebuns V's banishment (cold open) and life beyond the border; riders seen on the horizon; word that the Fyrd has crossed the Fells | a new region outside Bunsriel (the exile's home), the border passes | the **exile's kit**: no Bun Sword, a mercenary's blade, a lantern and a grapple |
| II. The Dark Forest | through the forest, now far wilder; the Temple of Bun in ruins; the dim Bun Sword | the Dark Forest (expanded), Temple of Bun (rebuilt as a ruin) | the **dim sword**: it can't cut Death Knights' armor until it is woken |
| III. The Burning Kingdom | Bunsriel in ruins: Haven, Castle Town and the fields, each occupied; free the strongholds; Death Knight lieutenants | the old regions changed, Saga-V-style (as the Chapter IV war versions were) | **Death Knights** (armor broken by charged blows), mounted combat on a new horse |
| IV. The Ancestors | captured; the castle dungeons played unarmed; the spirits of Gigglebuns I–IV each wake one power | the castle dungeons, the Path of Souls (a dream realm, like Lothelye's Dream) | **ancestor powers**: I, spirit form (the Path of Souls); II, gold-dust edge (Ladhellin's magic); III and IV, your choice |
| V. The Lord of Death | the escape; the duel with Camue from the dungeon to the courtyard; the fall | the castle, the courtyard | Camue: a multi-stage duel |

**The ending.** The lore ends with the hero's death and the kingdom's fall.
- Giggle 64 already did a lost battle in Chapter I.
- A sequel that ends on the fall would be bold, and true to Saga V. Saga VI would carry the hope forward, with ashes, the Eclipse War and the next Gigglebuns.
- Alternative: end on the fall, then a short epilogue in the style of Majora's Mask, where the people carry his memory and his sword is hidden away.

**Continuity with Giggle 64:**
- Gigglebuns IV's line goes on, so V is his son or grandson.
- Pip, now old, could be the castellan.
- The Questlords may cameo.
- Avalon and Lothelye may appear in the ancestors' chapter.
- Firebuns III's scythe hook leads straight into Camue's arrival.

## Making it

- **Engine:** copy Giggle 64 into a new project (a git fork or branch, `saga-v`). All of the systems carry over: the player, camera, combat, dungeon kit, tower kit, story and cutscenes, guidance, saving, the manual and promo pipelines.
- **Assets:** the world generators and character builders carry over. The new things are Camue, the Death Knights, Gigglebuns V (older, rougher, exiled), the exile region and the changed old regions.
- **Music:** a new main theme for Gigglebuns V built from your E minor motif; Camue's theme; and a funeral version of the main motif for the fall. MIDI first, as before (`g64midi.py`).
- **Order:** this saga_v_plan → a masterplan for the sequel (like `design/masterplan.txt`) → Chapter I as "alpha 1.0.0" of the new game.

## Questions for you

1. Keep the tragic ending, or soften it?
2. Who is Gigglebuns V to Gigglebuns IV (son, grandson, distant heir), and why was he banished?
3. What are the ancestor powers of Gigglebuns III and IV?
4. A new project, or a free Giggle 64 DLC-style "Saga V" campaign started from the title screen?
5. Which working title?
