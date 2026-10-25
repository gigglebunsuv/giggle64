# Beta 1.8.0 — Full Draw

An animation update. Every move Sir Gigglebuns makes has been reworked, the aimed items have proper first-person animations, sword hits land with weight, and a timed parry now opens the way to a riposte.

## First person
- **The bow, as it should look.** The aiming view now sits just behind his head, as the classic did, instead of a step and a half back. The bow is canted across the view and the drawing fist sits at the bottom edge.
  - An arrow is nocked on the string, and the string draws back to his fist. Loose it and the string snaps forward and quivers.
  - The whole cycle is animated: raise and nock, draw, hold (he breathes), loose, then fetch, nock and draw the next arrow.
  - Sun, Frost and Starfall Arrows show their own arrow on the string.
- **The Hookshot** is held out like a pistol, low at the right of the view, pointing at the reticle. It kicks when the chain fires, and the chain now leaves from its muzzle.
- **The Bloom Rod** is held out like a wand and flicked to sling the seed.
- **The boomerang** is wound back beside his ear, flung across his body and, on its way back, snatched out of the air.
- Holding the Hookshot or the Bloom Rod no longer leaves the sword hanging in the same fist.

## Impact
- **Sword hits now land with impact.** As the blade bites, the action holds for a few frames, then eases back to full speed through a brief slow-down. A finisher, a jump slash or the Great Spin holds longer, flashes the screen and shakes the camera. Shield Bashes and the Down Thrust hit with impact too.

## Sword trails
- **Every stroke leaves a trail**, modeled on the 1998 preview builds of the classic rather than its final release. It's a broad sheet of pale glass swept from the root of the blade to its tip, laid down in hard-edged facets with a bright line where the tip passed. It stays solid, then vanishes within a few frames.
- Cuts, finishers, the jump slash, both thrusts, the riposte and the slash from the saddle all leave one. **The Great Spin's trail is red**, as it was in those builds.
- The trail holds still through the impact frames along with everything else.

## The parry and the riposte
- **A parry is a moment now.** The shield flicks out, time stops for a beat, then runs slowly as the foe reels.
- **The riposte.** Press B while a parried foe is still reeling, close and in front of you. The camera swings in low beside the two of you, and he steps in and runs the foe through for three times a cut's damage. He holds the blade there, twists it and shoves the foe off. Nothing can hurt him while he does.

## Standing still
- **Idle fidgets.** Stand still a while and he fidgets, the way the classics' heroes did:
  - he looks around, stretches, tugs his tunic straight or knocks the dirt off his boots;
  - he sets his shield on his arm, or practices a swing with the sword out;
  - in the snows of Frostpeak he shivers and sneezes, and in the desert or near the cinders he mops his brow;
  - at critical health he doubles over, hands on his knees, panting until he's out of danger.
- **A battle stance.** Locked on to a foe and standing still, he crouches low with his shield up and the point of his blade on the foe, bobbing on the balls of his feet.

## Every other move
- **The sword:**
  - every cut now winds up with the weight on the back foot, with the hips driving it and the head leading;
  - the arm stretches past full reach at the middle, then the cut carries through and settles, the shield arm swinging the other way to balance him;
  - the chop lifts the back heel on the way up and sinks through the knees at the bottom, and the thrust drives off the back foot past full stretch;
  - finishers step right through.
- **The jump slash** crouches, springs with the blade swung up behind his head and the back arched, and lands in a chop that sinks into a deep crouch.
- **The Great Spin:** he trembles while gathering strength, then spins low and wide, leaning out against the turn with the shield arm flung out.
- **The Shield Bash** draws the shield in and rocks back before the shove. Raising the shield and taking a blow on it, standing or crouched, have a little give.
- **The side step** reaches and closes with a bob and a sway. Turning on the spot takes little pivoting steps.
- **The bonk** sits him down hard, and he shakes his head clear.
- **Slopes:** sliding downhill he wobbles for balance, and sliding backward he claws at the slope.
- **Ledges and ladders:**
  - hanging, he sways with his legs swinging loose;
  - pulling up starts with a kick, and stepping up and the leap for a high ledge come up cleaner;
  - on a ladder he sways toward the reaching hand.
- **In the water:** a proper breaststroke (reach, sweep, tuck, shoot, with the frog kick), sculling hands while treading water, and a kicking dive.
- **On horseback** he moves with Biscuit's stride at a walk and rises in the stirrups at the gallop.
- **Lifting** squats with a straight back and heaves through the legs. **Throwing** leans back, steps and follows through. **Holding up a treasure** dips first.
- **Story poses:** the knighting kneel breathes, dragging a stone heaves with each step, sleeping breathes slowly, and waking gets a stretch, a rub of the eyes and a scratch of the head.
- **Walking and running** strike with the heel and push off with the toe. The shoulders turn against the hips, and the head holds steady. The run leans in with high knees and pumping fists.
- **The ledge leap, falling and landing:** a real stride into the air, arms wheeling on the way down, and a squash and rebound on landing. A hard landing slams him onto one knee before he pushes himself up.
- **The roll** starts with a dive, the arms reaching for the ground, and comes up out of a crouch. **The backflip** swings his arms overhead. **Side hops** land softly.
- **Hit from behind,** he now pitches forward instead of being thrown back.
- **Falling in battle:** his knees give, he sags, then pitches onto his face.
- **Putting the sword away** starts with a twirl of the blade before it goes home over his shoulder.
- **Flying on the Hookshot's chain:** drawn out behind the launcher, his legs trailing.
- **Bottles:** the empty bottle is swept through the air to catch a fairy, drinks are tipped up with the head back, and letting something out tips the bottle forward. The bottle is in his hand for all of it.
- **Items with their own moves:**
  - the Puff Nut is snapped down from beside the ear;
  - the Iron Mallet is heaved overhead in both hands and brought down into a lunge;
  - the Grave Spade is driven in two-handed and levered back;
  - the Ember Rod is cocked and flicked;
  - the Sapphire Staff is raised, then pointed at the spot;
  - the Iron Flail is wound back, hurled and hauled in.
- **Each blessing has its own casting:**
  - Alan's Harvest: a prayer, then open arms;
  - Aphiel's Gale: arms flung high and wide;
  - Serielye's Ruin: fists raised, then punched into the earth;
  - Lothelye's Dream: hands raised slowly to the sky.

## Under the hood
- The hero's new animations are built from whole poses, with arms placed by where the fists must go. They're eased through smoothly, so an arm held straight out no longer twists between poses.
- The upper body can now play full animations, looping or held, over whatever the legs are doing, and eases from one into the next.
