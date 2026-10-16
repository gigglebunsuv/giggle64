# Beta 1.4.1 — Steady Hands

A small fix patch for Black Water Ridge.

## Fixes
- **The greatsword no longer eats Gigglebuns's hand.** With the Questlord's Greatsword drawn, his left hand used to swell a little more with every swing, then vanish. It now stays the right size on the grip for as long as you fight.
- **The waystone menu fits every waystone again.** Black Water Ridge made it thirteen stones, one more than the old 4 x 3 grid could hold, so the last picture fell off the panel and over the text. The menu is now a 5 x 3 grid with slightly smaller pictures, with room for two more stones.

## Under the hood
- New test: every waystone is visited in turn and must set you down on firm ground beside its stone.
- The greatsword test now swings six times and checks the left hand keeps its size.
