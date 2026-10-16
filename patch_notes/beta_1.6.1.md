# Beta 1.6.1 — Pages Turned

A pause screen update: a new journal with a quest tree, a restyled options page, a fog of war on the world map, and menu navigation that follows Ocarina of Time's pause screen more closely.

## The journal
- **Easier to read.** The quest text was drawn with a black drop shadow under dark ink, which smudged it on the parchment. It is now plain ink, and steps are written in ordinary sentence case instead of all capitals.
- **Every quest gets its own tab.** The list down the left gives each quest a tab:
  - the main story's chapters in gold;
  - errands in green-grey;
  - the Bestiary in violet;
  - finished quests faded, with a green tick.
- **The list scrolls.** It no longer runs off the bottom of the page; a scroll bar shows where you are.
- **Only the chosen quest on the right:** who gave it, its title, what to do **now**, and a bar showing how many of its steps are done.
- **NEW marks.** A quest you haven't read yet carries a red NEW badge on its tab until the cursor rests on it, and it comes back whenever one of its steps is done. While anything is new, the JOURNAL page-turn label says "JOURNAL NEW!".
- **The quest tree.** A on a quest opens its whole line of steps over the pause screen. Steps you've done are ticked in green and the one to do now glows gold. Steps still ahead stay hidden as "? ? ?" so nothing is spoiled. Scroll with the stick; B goes back.

## The options page
- Restyled:
  - every row is a plate with its name on the left and its setting on the right (ON in green, OFF in red, an arrow for a sub-list);
  - the chosen row is lit and outlined in gold;
  - gold rules separate the groups;
  - the list scrolls.
- **RESTART AREA and WARP are gone**: they were debug tools, and the debug menu (F1) has them.

## The world map
- **Heart Shards per region.** Under each region's dot sits a little heart for every Heart Shard there, red once you've found it. The region under the cursor spells it out, e.g. "HEART SHARDS 1 / 3". All 28 count, including the ones people give you.
- **Fog of war.** Regions you haven't visited lie under drifting cloud until you set foot in them. A dungeon or a house counts for the region it is in. The map cursor only visits regions you've seen. Old save files work too, since the game already remembered every place you'd been.

## Quest Status and the file select
- **Time played** shows on the QUEST STATUS page and on the file select. It counts while you play (not on the title or the pause screen) and is saved with the file; files from before this update start counting now.
- **How much is done**: QUEST STATUS shows the completion percent with a bar, counted the same way as on the file select.
- The pixel font has a percent sign at last (the file select's percent was missing it too).

## Menu navigation, after Ocarina of Time
- **The cursor skips empty slots** on SELECT ITEM and EQUIPMENT, moving on to the next thing you actually have, the way OoT's does.
- **Page-turn buttons.** Pushing past the edge of a page stops the cursor on that side's page-turn button, which lights up. Hold the stick there a moment or push again to turn the page, or push back to return to the page. Turning a page leaves the cursor on the new page's button on the side you came from, so pushing on enters the page at its first slot.
- **OoT's stick timing.** A held stick steps once, then repeats after half a second, then every three frames.
- **Saving.** B still asks "Would you like to save?". Whichever you answer, you now go back to the page you were on (OoT closes the whole pause screen here).

## Every scored cutscene plays on its music
Like Lothelye's legend, every cutscene with its own music now runs on that music's clock. Each moment waits for its place in the score, and the words go on by themselves, each box closing before its moment in the music passes. You no longer press A through them. (START still skips a scene you've seen.)
- **The prologue** in the Cinder Vault: the narrator over the ice; Firebuns III's five steps on the five cells of his motif; his words over the low brass; the ice cracking on the celesta's falling run; and the Gauntlet's fire bursting out with his theme.
- **The sealing of Firebuns** (Chapter IV): his flame fails as his figure slows; the ice forms on the celesta and choir; he rises into the stars as peace begins on the horn.
- **Serielye ends it** (the true ending): she appears on the bell; the shadow's last word over the lone violin; she closes her hand on the choir chord that closes like one; you take your hand off your sword as the strings open to D major; home on your own motif.
- **The Chapter I and Chapter IV endings**: their words over black come in on the music's bars, and the chapter card on the suspended bars that say "to be continued".
- **After the credits**: the scythe on the ridge catches the light as Firebuns' figure creeps in on the clarinet.
- The lead-ins and closing lines of these scenes, before or after their music, also go on by themselves, at reading pace.

## Fixes
- **A Heart Shard you could take twice.** During the war in Chapter IV, the four caves of Bunsriel Fields were new caves as far as the game knew: their Heart Shard, purple coin, gold coin and bomb bag upgrade could all be had a second time. The field at war now shares the field's caves.
- **The prologue's music.** The music of the hero's house kept playing under the CHAPTER I card and the prologue in the Cinder Vault, overlapping the prologue's own score. The house music now fades out as the opening begins, and comes back when he wakes at home.

## Under the hood
- `PauseMenu.edge` holds OoT's cursorSpecialPos (`_edge_input`, `_to_edge`, `_enter_page`). `tree_rows()` builds the quest tree and `region_seen()` decides the fog. `PixelFont.wrap` wraps text without changing its case.
- Scored scenes use `Story.start_score`, `_at_time` and `say_window`; `say_window` now records how late any box ran (`Story.score_late`). The cue tables are `StoryIntro.PROLOGUE_CUES`, `StoryChapter4.SEALED_CUES`, `StoryEnding.ENDING_CUES` and `Story.ENDING_PAGE_CUES`. `Story.say_auto` paces unscored lines by reading time.
- `HeartShards.SOURCES` lists all 28 Heart Shards by flag and area. Caves can be given a fixed flag (`world_kit.cave(..., flag)`). `Progress.play_time` is saved with the file.
- New tests:
  - test_pause_oot_navigation
  - test_world_map_fog
  - test_heart_shard_registry
  - test_journal_new_marks
  - test_play_time_and_completion
  - test_scored_scenes_keep_time
- Updated tests:
  - test_journal_page now covers the quest tree;
  - test_wake_up_at_home now checks the prologue is silent;
  - test_pause_item_sections now covers the page-turn button.
