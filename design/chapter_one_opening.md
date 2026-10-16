# Chapter I opening (PLANNED, not built yet)

Written 2026-10-13 (Beta 1.1.1). The chapter card system is in already
(`Story.chapter_card` / `chapter_scene`); this file is the plan for the
opening scenes that will go around Chapter I's card.

## Order of a new game

1. Black. **CHAPTER I / THE GAUNTLET OF FIRE** fades in and out
   (built: `Story.wake_up` opens on it today).
2. **Prologue: Firebuns seeks the Gauntlet** (to build). Short, about
   30 to 45 seconds.
3. **The hero asleep** in his bed at home (built: the current wake-up shots).
4. **The castle's messenger** (to build) wakes him and starts the main quest.

## 2. Prologue: Firebuns seeks the Gauntlet of Fire

Keep it short and mysterious. No names given on screen except his, and the
Gauntlet's.

- Night, a storm, somewhere far off (a dark ruin; the Gauntlet's resting
  place should match whatever the story later says it was).
- Firebuns III walks through rain and fire, only his silhouette and his eyes
  lit at first. Fire springs up along his path.
- He reaches the Gauntlet of Fire on its stand / in its vault. It glows as he
  comes near, as if it knows him.
- One or two lines from him, something like:
  - "There you are... I've waited a long time to hold you again."
  - (Optional) "Let Haven sleep a little longer."
- He reaches for it; a flash of fire fills the screen.
- Cut to black, then dawn: Haven Village, a slow pan to the hero's house.

Notes:
- Reuse the finale's fire tools (`_flames`, `_flash`, `_gauntlet`, the fire
  orb) and Firebuns' laugh sfx.
- Music: the Firebuns triplet motif, low and quiet (a short MIDI cue).
- Mark it skippable after it has been seen once, like every scene.

## 4. The castle's messenger

Replaces the current ending of the wake-up scene ("Time to see what the day
brings!"), so the main quest starts with a reason.

- Hard knocking at the door before the hero is fully up (or right as he hops
  out of bed).
- A **messenger from the Castle of Haven** (a castle guard or page in the
  castle's colors; new character, needs a model and a name) bursts in,
  out of breath.
- What they tell him (draft):
  - The castle sends for Sir Gigglebuns IV at once.
  - Something was taken in the night: the Gauntlet of Fire has woken, and
    fires were seen in the far country. (Exact wording to match the prologue
    and the Chapter I quest.)
  - He is to start at **Mirror Lake** (the Lake Shrine is Chapter I's first
    step in the journal), or to report to someone who will send him there.
- The messenger hurries off; the hero is free. The journal's Chapter I quest
  starts here (flag "woke_up" today; could become "messenger_met").

Open questions for later:
- The messenger's name and look, and whether they show up again (e.g. in
  Castle Town, or in the shelter in Chapter II).
- Who sent them: the king/queen, the Questlords, or Princess Himeko? (Himeko
  already bursts in at the start of Chapter II, so a different face here
  keeps the two mornings from feeling the same.)
- Whether the prologue plays before or after the CHAPTER I card. The plan
  above puts the card first.

## Chapter cards (built in Beta 1.1.1, for reference)

| Chapter | Title | When the card shows |
|---|---|---|
| I | THE GAUNTLET OF FIRE | New game, before the hero wakes |
| II | THE GAUNTLET'S TRAIL | The morning after the first ending, at home |
| III | THE BATELA FELLS | After reading the Order's map in the Sun Trial |
| (end) | END OF CHAPTER I / III | The first ending; Ottilie reading the Prophecy |

New chapters: add the quest ("ch4", its title) to `Quests.QUESTS`, then call
`Story.chapter_card(4)` in the chapter's first scene, or mark a dialogue page
with `"chapter_card": 4` (`"chapter_end": n` for the end card).

The credits roll only at the very end of the game (masterplan, Chapter V
step 10). Until then they are under OPTIONS > CREDITS.
