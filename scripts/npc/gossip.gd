class_name Gossip
extends RefCounted
## What the people of Bunsriel are saying (Beta 1.5.0): the story's next step,
## told in the world rather than the journal. Townsfolk in the houses and the
## market pass on the RUMOR for the main quest's current step; Pip, the
## King's page and Castle Town's herald, cries it as NEWS. Keyed by each
## step's condition in Quests.QUESTS, so a rumor always matches the journal.

## [condition, the townsfolk's rumor, the herald's news]
const TALK := [
	# Chapter I
	["flag:lake_shrine:r7_clear",
		"They say the old *Lake Shrine* on *Mirror Lake* has opened, out east past the South Road. Mira who lives on the shore says strange lights move under the water.",
		"Hear ye! The King seeks the goddesses' blessing! The way begins at the *Lake Shrine* on *Mirror Lake*, east along the South Road!"],
	["flag:bun_piece:alan",
		"Farmers in the *Southern Fields* say the old *Southern Tower* has woken up. Alan's own tower, from the legends. Lights in the windows at night!",
		"Hear ye! The first of the goddesses' towers stands in the *Southern Fields*, west of Haven Village! Alan's piece of the Bun waits at its top!"],
	["flag:bun_piece:serielye",
		"A trader came in from the desert, white as a sheet. Said the *tower of Ladhellin* moans in the sandstorms. Serielye's tower, out in the *Desert of Ladhellin*, east of the field.",
		"Hear ye! Serielye's tower rises from the *Desert of Ladhellin*, east of the field! The second piece of the Bun lies within!"],
	["flag:bun_piece:aphiel",
		"Up past the *Northeastern Cliffs*, on *Frostpeak*, there's a spire that goes right up into the clouds. *Skyreach*, the old songs call it. Aphiel's home.",
		"Hear ye! *Skyreach Spire*, on Frostpeak beyond the Northeastern Cliffs, holds Aphiel's piece, the last of the three!"],
	["item:bloom_rod",
		"Out in the *West Marshlands* there's a rotten old tower leaning in the reeds. The *Bog Tower*. Marsh folk say there's a rod in there that makes things grow, even on water.",
		"Hear ye! The *Bog Tower* in the West Marshlands hides a gift of growing things! Brave the bog before you storm anything else!"],
	["flag:legend_told",
		"Three pieces of the Bun, they say, and the sword wakes in the *Hidden Forest*, past the woods north-west of the field. My gran swore she saw it once, in a stone, under a tree like a cathedral.",
		"Hear ye! With the goddesses' three pieces, the *Bun Sword* may be drawn! It waits in the *Hidden Forest*, beyond the woods to the north-west!"],
	["flag:castle:rescued",
		"Have you seen it? The castle's burning! *Firebuns* is in there with the Gauntlet. Pink and the Questlords went in after him and never came out.",
		"Hear... hear ye... oh, never mind hear ye. The castle has fallen! Get inside, through the broken gate north of the square, and save who you can!"],
	["flag:game_beaten",
		"He's on the throne. Up at the top of the castle. Sitting there, like he owns us.",
		"Firebuns III sits on the throne of Haven, at the very top of the castle! Someone has to face him!"],
	# Chapter II
	["flag:ch2:shelter_met",
		"Castle Town's people are all at *Princess Himeko's palace*, here in Haven Village. Packed in like fish. She's been ever so kind about it.",
		"Survivors of Castle Town! Gather at Princess Himeko's palace in Haven Village!"],
	["item:iron_mallet",
		"Aladriel's been asking after the castle armory. Something about a hammer that can break anything. Sounds like someone has to go back into that castle.",
		"The Questlords need the *Iron Mallet* from the castle armory! Through the ruins of Castle Town and into the castle!"],
	["flag:visited:frostpeak_hollow",
		"There's a frozen waterfall up on *Frostpeak* that's never thawed. The Questlords think there's a cave behind it. You'd need to smash it, mind.",
		"The Questlords have found a hollow behind the frozen falls of *Frostpeak*! A mighty hammer could open it!"],
	["flag:frostpeak_hollow:boss_clear",
		"Something lives down in that *Frostpeak Hollow*. You can hear it roar from the hut, Hilde says.",
		"Something stirs in the depths of *Frostpeak Hollow*! Be brave!"],
	["flag:ch2:bracers",
		"*Aladriel's* waiting at the palace to hear what you found up the mountain. She doesn't wait well.",
		"Aladriel of the Questlords awaits news from Frostpeak at Himeko's palace!"],
	["flag:visited:sun_trial",
		"There's a great stone sitting on something in the *desert*. The Questlords say it's the way into the *Sun Trial*. Too heavy to lift without help.",
		"A great stone seals the *Sun Trial* in the Desert of Ladhellin! Only mighty arms will lift it!"],
	["flag:sun_trial:done",
		"The Sun Trial's open, they say. Full of light and mirrors. My cousin went in and came out with no eyebrows.",
		"The *Sun Trial* lies open in the desert! Pass it, and learn where the Gauntlet's trail leads!"],
	["flag:ch2:trail_found",
		"Whatever's at the bottom of that Sun Trial, the Questlords say it tells where Firebuns went. Read it and you'll know.",
		"At the heart of the Sun Trial lies the answer: where the Gauntlet's trail leads!"],
	# Chapter III
	["flag:visited:batela_fells",
		"East of the desert, the *Forest of the Dead*. Nobody comes back the same. They say the lost souls show the way, if you watch them, and listen for the bells.",
		"The trail leads *east* past the desert, through the *Forest of the Dead*! Follow the wisps! Mind the bells!"],
	["flag:ch3:maud_met",
		"People live out in the *Batela Fells*, believe it or not. A camp called *Ashwick*. The ones who got away when Firebuns burned his own country.",
		"Survivors of Batela camp at *Ashwick* in the Fells! Their elder, Maud, may help you!"],
	["flag:ch3:keep_duel",
		"The ruins of *Batela Keep* sit up on the ridge in the Fells. That's where he ruled. Where they say he died the first time.",
		"Batela Keep, on the ridge of the Fells! Firebuns' old seat! Tread carefully!"],
	["flag:ch3:confession",
		"Elder Maud's been crying, they say. Something she's carried a long time. Somebody should sit with her.",
		"Elder Maud of Ashwick wishes to speak with you!"],
	["flag:visited:sapphire_sanctum",
		"There's a crypt under the old chapel in the Fells, west of Ashwick. Blue lights at night. Robed folk going in and out.",
		"The Sapphire Order hides beneath the old chapel of the Fells! The crypt gate, west of Ashwick!"],
	["flag:starlight",
		"In the old tales, Lothelye's starlight is the one light the Gauntlet can't command. If it's anywhere, it's somewhere deep.",
		"Seek Lothelye's starlight! It is said to lie deep in the Order's own Sanctum!"],
	["flag:sapphire_sanctum:boss_clear",
		"Something horrible guards the bottom of that Sanctum. Made of pages, someone said. Pages with teeth.",
		"A beast of torn pages guards the depths of the Sapphire Sanctum!"],
	["flag:ch3:seal_cracked",
		"The Order's doing some sort of ritual, down under the Fells. Everyone felt the ground shiver last night.",
		"The Sapphire Order works a ritual beneath the Fells! It must be stopped!"],
	["flag:ch3:prophecy_read",
		"*Ottilie* at the library reads anything. If you've brought something back written in the Order's hand, she's the one to show.",
		"Haven Library! Ottilie the librarian can read the Order's dark writings!"],
	# Chapter IV
	["flag:ch4:captain_met",
		"*Captain Rowena's* in the refuge, giving orders like the whole war's hers. Go see her. She'll have work for anyone with a sword.",
		"WAR! Northwatch burns! All who can fight, report to *Captain Rowena* in the refuge!"],
	["flag:ch4:camps",
		"Three goblin camps out on the field, lit up like bonfires. Rowena wants them broken before they march on us.",
		"Three goblin war camps on Bunsriel Fields! Break them before they reach the village!"],
	["flag:ch4:siege_won",
		"They're coming tonight. All of them. Rowena says hold the palisade, or there's no more Haven.",
		"Tonight they come for Haven! Hold the palisade! Hold the gate!"],
	["flag:visited:westmarch_fortress",
		"*Westmarch Fortress*, west of the field: last anyone heard, Idrith and Aladriel were holding it with a handful of soldiers.",
		"Westmarch Fortress still stands, west of the field! The Questlords hold it! Go to them!"],
	["flag:westmarch_fortress:boss_clear",
		"There's a great ogre of a goblin at Westmarch, smashing the walls with his head. Grukk, they call him. Grukk the Siegebreaker.",
		"Grukk the Siegebreaker batters Westmarch! Break him!"],
	["flag:ch4:despair",
		"Get them home. Whoever's still alive out at Westmarch, get them home to Haven.",
		"Bring the survivors of Westmarch home!"],
	["item:grave_spade",
		"Wren, the gravekeeper at *Ashwick*, knows every buried thing in Bunsriel. If there's a way into anywhere underground, ask Wren.",
		"Wren the gravekeeper of Ashwick knows the buried ways! Ask Wren!"],
	["flag:ch4:temple_found",
		"The *Dark Forest*, south of the desert. The prophecy says a grove. Only starlight shows the true road in there, they say.",
		"The sacred grove lies in the *Dark Forest*, south of the desert! Let starlight guide you!"],
	["flag:ch4:sword_awake",
		"There's a temple under that grove, if the old songs are true. The Temple of Bun. Where a sword goes to wake up.",
		"The Temple of Bun! Pass its trial, and the sword shall wake!"],
	["flag:ch4:astral_seal",
		"They say Lothelye herself waits at the heart of that temple. Imagine.",
		"At the heart of the Temple, Lothelye waits with a gift!"],
	["flag:visited:citadel_assault",
		"The castle's a citadel of fire now. Firebuns made it his. Somebody has to go in there and end it.",
		"Storm the Burning Citadel, where the castle once stood!"],
	["flag:ch4:sealed",
		"He's up on the throne-room roof, laughing, with fire all round him. Only Lothelye's light breaks that shield, they say.",
		"Firebuns stands on the Citadel's roof! Break his flame shield with starlight, and seal him away!"],
	# Chapter V
	["flag:ch5:yard_met",
		"Commander Rowena's in the *Knights' Yard*, by the castle gate. A new knight always reports to her first.",
		"Sir Gigglebuns IV, knighted! Report to Commander Rowena in the Knights' Yard!"],
	["flag:ch5:trained",
		"Rowena's got trials for every new knight in the yard. The spin, the thrust, the bash. Nobody passes first time. Well. Nearly nobody.",
		"The Knights' Yard! Rowena's three trials await!"],
	["flag:visited:barrow_of_kings",
		"The *old royal chapel*, east of the square, opened up on its own. The *Barrow of Kings* is under it. Nobody wants to go down there.",
		"The Barrow of Kings has opened beneath the old chapel, east of the square! The dead walk!"],
	["flag:barrow_of_kings:boss_clear",
		"There's a king down in the Barrow who won't lie still. A hollow one, they say. His crown rattles.",
		"The Hollow King stirs in the Barrow! Lay him to rest!"],
	["flag:visited:cinderhold",
		"Firebuns went *east*, past the *Northeastern Cliffs*, to *Cinderhold*: Serielye's old volcano. There's a great stone across the pass. You'd want strong gauntlets.",
		"The burning one has gone to *Cinderhold*, beyond the Northeastern Cliffs! A great stone bars the eastern pass!"],
	["flag:visited:cinder_vault",
		"Somewhere in Cinderhold there's a vault, they say, where the Gauntlet was first kept. Frozen shut, long ago.",
		"Find the way into the Cinder Vault, deep in Cinderhold!"],
	["flag:cinder_vault:boss_clear",
		"A serpent of lava lives in the Cinder Vault, they say. Cold arrows crust it over. That's when you strike.",
		"A lava serpent guards the Cinder Vault! Frost first, then the blade!"],
	["flag:ch5:cinder_done",
		"At the heart of the Vault there's an old anvil. That's where he went. To make the Gauntlet burn again.",
		"Reach the Gauntlet's cradle at the heart of the Cinder Vault!"],
	["flag:ch5:front_seen",
		"Rowena took the knights *west*, to the end of the *West Marshlands*. Black water everywhere. They've made camp there.",
		"The knights of Haven camp at the west end of the *West Marshlands*! Join them!"],
	["flag:front:parry_done",
		"Rowena's teaching the knights something new at the marsh camp. Hitting the enemy's blow back at them, or some such.",
		"Commander Rowena teaches the Parry at the marsh-front camp!"],
	["flag:ch5:ridge_reached",
		"*Black Water Ridge*, past the black water. That's where Mara's army is. Where the dead are strongest.",
		"Firebuns and Mara march on *Black Water Ridge*, west beyond the marshes!"],
	["flag:ch5:camps_done",
		"Mara's got three camps on the Ridge, each with a bone fire. Rowena's knights are waiting for someone to lead them in.",
		"Break Mara's three camps on Black Water Ridge, with the knights of Haven!"],
	["flag:visited:ridge_keep",
		"With the camps broken, the chains on *Ridge Keep's* gate snapped. It's up at the top of the falls.",
		"Ridge Keep's gate lies open at the top of the falls!"],
	["flag:ch5:mara_done",
		"Mara's at the very top of Ridge Keep. Waiting, they say. On the roof, where the falls begin.",
		"Mara, Scourge of Bunsriel, awaits at the top of Ridge Keep!"],
	["flag:ch5:rift_seen",
		"Mara's gone! But there's a crack in the sky over the Ridge now. Commander Rowena's still up there, watching it.",
		"Mara has fallen! Commander Rowena awaits on Black Water Ridge!"],
	["flag:ch5:velloran_met",
		"The last of the Sapphire Order are hiding in the *Batela Fells*, in the crypt under the old chapel. Their Archmagus with them.",
		"The Sapphire Order makes its last stand beneath the old chapel of the *Batela Fells*!"],
	["flag:ch5:velloran_done",
		"Velloran, the Order's master, is at the bottom of that crypt in the Fells. They say steel just bounces off him. Starlight, though...",
		"Archmagus Velloran holds the Sanctum's ruin! Starlight breaks his ward!"],
	["flag:ch5:dream",
		"My little one dreamed of a lady in starlight, at a spring on an islet in the *West Marshlands*. Woke up saying someone has to go to her.",
		"Lothelye calls from her spring on the islet in the *West Marshlands*!"],
	["flag:ch5:rift_open",
		"Whatever's behind that crack in the sky over *Black Water Ridge*... someone's going to have to go up there and open it the rest of the way.",
		"To the top of *Black Water Ridge*! Raise the Astral Seal beneath the crack!"],
	["flag:astral_rift:lock4",
		"There's a door in the sky over the Ridge now. My husband swears he saw stars inside it... and then no stars at all.",
		"The Astral Rift lies open over Black Water Ridge! Light its four stars!"],
	["flag:rift:blessed",
		"Somewhere at the top of that Rift, they say, there's a stair made of dreams. You'd have to be asleep to climb it. Or a knight.",
		"Climb the dream stair to the heart of the Rift!"],
	["flag:ch5:firebuns_end",
		"Everyone's lighting candles tonight. For the knight in the sky. Come home safe, Sir Gigglebuns.",
		"Haven prays for its knight! Go, Sir Gigglebuns! End it!"],
]

## After the true ending, the whole kingdom says the same thing.
const PEACE := "It's over. Really over. The sky's closed up and the fires are out. My grandchildren will hear about you, Sir Gigglebuns. I'll make sure they do."
const PEACE_NEWS := "Hear ye, hear ye! Firebuns III is no more! The sky is whole! Bunsriel is at PEACE! ...I just like saying it. PEACE! Ha!"


## The main story's next step, as its condition ("" when there is none).
static func current() -> String:
	# After the true ending there is nothing left to point at (even on a file
	# that skipped a step on the way, such as a debug start).
	if Progress.flag("ch5:firebuns_end"):
		return ""
	var best := ""
	for q: Dictionary in Quests.QUESTS:
		if q.kind != Quests.MAIN or not Quests.check(String(q.start)):
			continue
		for st: Array in q.steps:
			if not Quests.check(String(st[1])):
				best = String(st[1])
				break
	return best


static func _row(cond: String) -> Array:
	for r: Array in TALK:
		if r[0] == cond:
			return r
	return []


## The townsfolk's rumor about the next step (a page dict).
static func rumor(anim := "talk") -> Dictionary:
	if Progress.flag("ch5:firebuns_end"):
		return {"text": PEACE, "anim": "happy"}
	var r := _row(current())
	if r.is_empty():
		return {"text": "Strange days, Sir Gigglebuns. Strange days.", "anim": anim}
	return {"text": String(r[1]), "anim": anim}


## The herald's news (Pip in the square).
static func news() -> Dictionary:
	if Progress.flag("ch5:firebuns_end"):
		return {"text": PEACE_NEWS, "anim": "happy"}
	var r := _row(current())
	if r.is_empty():
		return {"text": "No news today, Sir Gigglebuns! Which is good news, really.", "anim": "talk"}
	return {"text": String(r[2]), "anim": "talk"}
