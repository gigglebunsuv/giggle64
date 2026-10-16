class_name HouseLines
extends RefCounted
## The people in the houses (Beta 1.5.0, HouseData): Castle Town's homes and
## shops, Haven's cottages and Ashwick's tents. Each has a few words for each
## time of the story (era()): before the fall ("ch1"), the fall ("fallen":
## Castle Town's people are refugees in Haven), the war ("war"), the peace
## ("peace"), the years after ("ch5") and the true ending ("end"). Every
## other time you speak to them they pass on the talk of the day instead
## (Gossip.rumor: the story's next step, told in the world).

const LINES := {
	# --- Castle Town ---------------------------------------------------------
	"Nell Brightwater": {
		"ch1": ["Washing day, every day. Castle Town makes a lot of dirty laundry, Sir Knight. Mostly the castle guards. Don't ask about the castle guards."],
		"fallen": ["We got out with the clothes on our backs. Princess Himeko took us in. I'm washing her curtains to say thank you. She has a LOT of curtains."],
		"peace": ["Home again! The walls still smell of smoke, but they're our walls. I've washed them four times."],
		"ch5": ["My daughter's grown and married now. She does the washing. I just tell her she's doing it wrong. It's the best job I've ever had."],
		"end": ["I hung every sheet in the house out of the window when we heard. Like flags. The whole street did."],
	},
	"Bettany": {
		"ch1": ["Fresh buns! Well, I'd sell you one, but you look like the sort who'd eat it in one bite and then be sad. Here, smell the oven. That's free."],
		"fallen": ["My poor oven. Twenty years that oven and I were together. Himeko's kitchen will do for now. It's very pink."],
		"peace": ["The oven survived! Under all that rubble! I cried on it a bit. It's fine, it dried."],
		"ch5": ["Knight's buns, half price, for knights. You're the only knight who comes in, so really it's Gigglebuns buns."],
		"end": ["I baked a bun as big as a cartwheel for the celebration. It's in the square. People keep climbing it."],
	},
	"Old Tobias": {
		"ch1": ["I remember when the Bun Sword was only a story. Still is, mostly. But my gran saw it once, in the Hidden Forest, in a stone. Under a tree like a cathedral."],
		"fallen": ["Eighty years I lived in that house. Eighty! Then a man with a burning hand walks in and I have to live with a princess. At my age."],
		"peace": ["Back home. My chair's still here. The fire burned everything around it and left my chair. There's a lesson in that. I don't know what it is."],
		"ch5": ["Still alive! Everybody keeps being surprised. I'm going to outlive the lot of you out of spite."],
		"end": ["I told you I'd see the end of that Firebuns. Nobody believed me. Nobody ever believes old men. We're always right."],
	},
	"Fenwick": {
		"ch1": ["Fenwick's Fine Cloth! Sir Knight, that tunic is... brave. Very brave. Come back when you can afford something less brave."],
		"fallen": ["All my bolts of silk! Burned! I saved one ribbon. One. I'm wearing it. It's a statement."],
		"peace": ["Shop's open again. Everyone wants black for mourning, or bright colors for hope. Nobody wants anything in between. I understand them."],
		"ch5": ["A knight's tabard! Haven blue and silver! Did Himeko pick the trim? It's exquisite. I'm not jealous. I'm very jealous."],
		"end": ["I'm making banners for the victory feast. Thirty of them. My fingers are bleeding. I've never been happier."],
	},
	"Wick": {
		"ch1": ["Are you a REAL knight? Have you got a real sword? Can I hold it? Can Lark hold it? Lark can't hold it, she'd poke someone."],
		"peace": ["We saw Firebuns get frozen! Well, we saw the light from the roof. Lark says she saw his face. Lark lies."],
		"ch5": ["I'm going to be a knight too! Commander Rowena said come back when I can lift the practice sword. I'm practicing with a broom."],
		"end": ["When I'm a knight I'm going to fight a dragon. You've done everything else already. You have to leave me something!"],
	},
	"Lark": {
		"ch1": ["Wick says you're a knight. I think you're just a person with a sword. ...Can I see it though?"],
		"peace": ["I DID see his face. He looked sad. Wick doesn't believe me. Wick's a turnip."],
		"ch5": ["I'm going to be a knight AND a princess. Himeko says you can be both. She'd know."],
		"end": ["I made you a crown out of daisies. It's for being brave. Bend down. ...There."],
	},
	"Garth": {
		"ch1": ["Carrots, cabbages, the finest turnips in Bunsriel. The Southern Fields grow 'em big. Farmers there say the old tower's been lit up lately, mind. Spooky."],
		"fallen": ["Garden's ash. Everything's ash. I'll plant again. You always plant again."],
		"peace": ["First carrot of the new year! Look at it. It's tiny. I love it so much."],
		"ch5": ["Business is good! Peace makes people hungry. War makes them hungry too, but they don't pay."],
		"end": ["Free cabbages for the feast! Take two! Take ten! I grew too many on purpose!"],
	},
	"Master Quill": {
		"ch1": ["Maps, Sir Knight! Every road in Bunsriel. Well, every road I've been down. The far east is blank. Nobody comes back from the far east to tell me about it."],
		"fallen": ["My maps! I saved them! Rolled up under my arm all the way here. Look: Mirror Lake, the towers, Frostpeak. All still there, at least on paper."],
		"peace": ["I'm adding the Batela Fells to my map at last. And the Dark Forest. You've given me more work than the last forty years."],
		"ch5": ["I drew Black Water Ridge today from what the knights told me. Very black. Lots of water. Accurate, I think."],
		"end": ["I don't know how to draw a crack in the sky closing up. I've drawn a sun there instead. It felt right."],
	},
	"Granny Fennel": {
		"ch1": ["Come in, dear, come in. Sit. Eat something. You're too thin for a knight. Knights should be round, like buns. It's in the name."],
		"fallen": ["Himeko's cook doesn't put enough butter in anything. I've been showing her. She's learning. Slowly."],
		"peace": ["My kitchen! I'll make you a proper stew. You'll stay for supper. That wasn't a question, dear."],
		"ch5": ["Sir Gigglebuns! You're still too thin. Knighthood's made you thinner. Sit. EAT."],
		"end": ["I always knew. Since you were little and hit the rooster with a stick. A born hero, I said. Your gran didn't agree. She liked that rooster."],
	},
	"Rosalind": {
		"ch1": ["Welcome to the Golden Bun! Best ale in Castle Town, worst singing in Bunsriel. The band's working on it. Sit anywhere that isn't sticky."],
		"peace": ["We rebuilt the Golden Bun board by board. The band played the whole time. It was horrible. It was perfect."],
		"ch5": ["Knights drink free! One drink. One. Brannoc, if you're listening, ONE."],
		"end": ["The band's playing their own song tonight. Wrote it themselves. Loud as anything. Sit down, Sir Knight. This one's for you."],
	},
	"Lute Player": {
		"ch1": ["We're the house band! We know three songs. Two of them are the same song. The third one's about a goat."],
		"peace": ["New song! It's about you! It rhymes 'Gigglebuns' with 'sticky buns'. We're very proud of it."],
		"ch5": ["We've been practicing something big. Something really big. Come back when it's all over and we'll play it for you."],
		"end": ["It's finally ready. Our own song. We call it *Age of Enlightenment*. Hold on to something."],
	},
	"Drummer": {
		"ch1": ["*BOOM*. Sorry. *boom*. I'm the drummer. I'm always the drummer."],
		"peace": ["I drummed through the whole siege, you know. In the refuge. For morale. Nobody asked me to. Nobody asked me to stop either. They wanted to."],
		"ch5": ["We're writing something. It's loud. Rosalind says it's too loud. That's how you know it's good."],
		"end": ["This is it! The big one! *Age of Enlightenment*! ONE, TWO, THREE, FOUR!"],
	},
	"Fiddler": {
		"ch1": ["The fiddle's older than the town! Well. Older than me. It was my grandmother's. She was terrible at it too."],
		"peace": ["I played for the families coming home. I didn't know what song. I just played. People cried. Good crying."],
		"ch5": ["Shh, don't tell the others: the new song has a fiddle solo. A really long one."],
		"end": ["Here comes my solo! Don't blink!"],
	},
	"Captain Ostrin": {
		"ch1": ["Retired from the Haven Guard, thirty years. I still wake at dawn and polish a sword I don't carry. Old habits."],
		"fallen": ["If I were twenty years younger I'd have been at that castle gate. Instead I was in bed with my bad knee. I'll never forgive this knee."],
		"peace": ["Rowena was my recruit, you know. Snot-nosed little thing. Now she's captain. Now she gives ME orders. I like her very much."],
		"ch5": ["Commander Rowena! My recruit! A commander! And she knighted YOU. Hah! I'm getting old. I like it."],
		"end": ["Thirty years in the Guard and I never saw anything like what you've done. Sit down, Sir Knight. Let an old soldier salute you properly."],
	},
	"Silas Goldthread": {
		"ch1": ["Silks from Ladhellin, spice from the south, a very nice spoon. The desert road's been dangerous lately, though. Sandstorms that moan, they say. Round the old tower."],
		"peace": ["Trade's back! Ashwick's people have started weaving again, and their cloth sells like fire. ...Poor choice of words. Sells very well."],
		"ch5": ["I've a ship's worth of cloth from the Fells now. Batela gray. All the fashion. Who'd have thought?"],
		"end": ["Prices are up, everyone's happy, nobody's on fire. Best year for business I've ever had. Thank you, Sir Knight. I mean it."],
	},
	"Dunstan": {
		"ch1": ["I fish the canal. Mostly I catch boots. Mira out at Mirror Lake catches proper fish. Lake's full of 'em. And something else, she says. Lights under the water."],
		"peace": ["The canal's full of soot. The fish don't mind. The boots don't mind either."],
		"ch5": ["Caught a fish today. A real one! First in eleven years! I've named him. I couldn't eat him after that. He lives in a bucket now."],
		"end": ["The fish in the bucket is called Gigglebuns now. He's very brave. He's a very brave fish."],
	},
	"Mabel Meadows": {
		"ch1": ["I come in from the Southern Fields for market day. Big old tower down there. Alan's tower, gran called it. It's been humming at night lately."],
		"peace": ["Farm's fine! Goblins trampled the beans but missed the barley. I'm counting that as a win."],
		"ch5": ["The undead walked through my fields last month. Didn't eat anything. Just walked. I'm still not over it."],
		"end": ["Biggest harvest in years coming. The ground knows. The ground always knows when it's peace."],
	},
	"Pim the Toymaker": {
		"ch1": ["Little wooden knights! This one's you. Well, it's a knight. I'll paint it red. Now it's you."],
		"peace": ["Every child in town wants a little wooden Gigglebuns now. I've made sixty. My hands hurt. My heart's full."],
		"ch5": ["New toy: Knight Gigglebuns, with a little cape that flutters! The cape falls off. I'm working on it."],
		"end": ["I made one more. The last one. It's you and a goddess with a halo, and you're not fighting. Nobody understands it. You do, I think."],
	},
	"Sister Agnes": {
		"ch1": ["I keep the little shrine to the three goddesses at the end of the street. Alan for the harvest, Aphiel for the sky... and Serielye. Nobody leaves flowers for Serielye."],
		"peace": ["I prayed every night of the war. I don't know if anyone heard. Something did. Something answered."],
		"ch5": ["Someone's been leaving flowers for Serielye at last. A single red one, every morning. I don't know who."],
		"end": ["You saw her? Serielye? ...And you did not draw your sword. Bless you, child. The first of your line would be proud. And a little embarrassed."],
	},
	"Clemence": {
		"ch1": ["Candles! For dark nights and darker cellars. They say the castle's cellars go down forever. Under the castle there's an old crypt full of kings."],
		"peace": ["I've never sold so many candles. One in every window, for the ones who didn't come home."],
		"ch5": ["The crypt under the chapel opened by itself, they say. The Barrow of Kings. I've sold every candle I had to people who will NOT be going down there."],
		"end": ["Tonight I'm lighting every candle in the shop. For no reason at all. Just because I can."],
	},
	"Bram": {
		"ch1": ["Barrels, buckets, tubs! Hoops too tight, staves too dry, I fix it all. Need a barrel? Everyone needs a barrel."],
		"peace": ["Rebuilding takes a lot of buckets. Water for the mortar. I'm a very busy cooper."],
		"ch5": ["The knights ordered fifty water barrels for the march west. To Black Water Ridge. I asked if they wanted black barrels to match. They did not laugh."],
		"end": ["I'm making the biggest barrel I've ever made. For the feast. For the cider. Don't tell Rosalind."],
	},
	"Hazel": {
		"ch1": ["Hazel's Remedies! Red potion for a scrape, a dab of salve for a burn. Fairies in a bottle work better, if you can catch one. The springs are full of them."],
		"peace": ["Burns, mostly, all winter. I've learned more about burns than I ever wanted to. My salve's very good now."],
		"ch5": ["Undead scratches go green if you leave them. Come straight here if you get one. Don't be brave about it."],
		"end": ["I'm going to brew something nice for once. Something that smells of flowers. No reason. Just because."],
	},
	"Rowan": {
		"ch1": ["We were married last week! In the square! The fountain was very wet. Everything was very wet. It was perfect."],
		"peace": ["We spent the war apart. Ivy in the refuge, me on the wall. Never again. We decided. Never again."],
		"ch5": ["We have a little one now! She's asleep. Please talk quietly. Please talk very quietly. Please."],
		"end": ["Our little one's first word was 'knight'. We think. It might have been 'night'. We're choosing 'knight'."],
	},
	"Ivy": {
		"ch1": ["Rowan thinks it was his idea to marry me. It was my idea. Don't tell him."],
		"peace": ["Our house was one of the lucky ones. Smoke damage, that's all. We're keeping the black on that one wall. To remember."],
		"ch5": ["She has your nose, Rowan says. Not YOUR nose, Sir Knight. Rowan's. Sorry."],
		"end": ["When she's older we'll tell her about the night the sky closed up. And who closed it."],
	},
	"Sergeant Holt": {
		"ch1": ["Served at Northwatch for twenty years. Cold, windy, nothing ever happens. Best years of my life."],
		"peace": ["Northwatch burned. My old post. I went out to see it after. Just stood there a while."],
		"ch5": ["The new knights are soft. Every generation says it. Every generation's wrong. They're doing fine."],
		"end": ["I'm going back to Northwatch. They're rebuilding it. Somebody has to tell the young ones where the drafts are."],
	},
	"Odo the Bookbinder": {
		"ch1": ["I'm binding a new copy of the Legend of the Bun. Three goddesses, a nameless hero, a sword. You know the one. Everyone knows the one."],
		"peace": ["Ottilie at the library sent me pages from something called the Fari Incunabulum to bind. I won't. I won't touch it. It's warm."],
		"ch5": ["The Kings' epitaphs from the Barrow! The knights copied them out. I'm binding them into a book. Some of them are very rude."],
		"end": ["I'm starting a new book. A blank one. The story of what happened. You'll have to tell me all of it. Take your time."],
	},
	"Tansy's Cousin": {
		"ch5": ["I moved in last month! Tansy says hello. Tansy also says you still owe her a round of cups. She's keeping count."],
		"end": ["I'm painting the whole house yellow. For the sun coming back. Tansy says it's too much. Tansy is wrong."],
	},
	"Melody": {
		"ch1": ["I practice here so the tavern doesn't hear me. They say I'm too good for them. I think they mean too loud."],
		"peace": ["I wrote a lament for the ones we lost. I can't play it all the way through yet. One day."],
		"ch5": ["I can play the lament now. All the way to the end. It took me years. Do you want to hear it? Not today. One day."],
		"end": ["I'm going to the Golden Bun tonight. The band's playing something new. I want to hear what peace sounds like."],
	},
	"Widow Purrington": {
		"ch1": ["Watch the cats, dear. That's Biscuit, that's Muffin, that's Lord Bubbles. Lord Bubbles is the important one."],
		"fallen": ["I carried all eleven cats to Haven in a basket. In ONE basket. I don't want to talk about it."],
		"peace": ["The cats are home. Lord Bubbles sat on the windowsill and stared at the castle for a week. I think he was angry at it."],
		"ch5": ["Lord Bubbles is very old now. He sleeps in the sun all day. He's earned it. He survived Firebuns. Twice."],
		"end": ["Lord Bubbles woke up today, looked out of the window, and purred. He knows. Cats always know."],
	},
	"Cobbler Jory": {
		"ch1": ["Boots for the long road, Sir Knight. Every hero needs good boots. The legends never mention the boots. The boots do all the walking."],
		"peace": ["Everyone's walked their boots to ribbons this year. I'm making them faster than I can sleep."],
		"ch5": ["Knight's boots, steel toes, Haven blue laces. Rowena ordered a hundred pairs. I may never see daylight again."],
		"end": ["I made you a pair of slippers. For the peace. You've walked far enough, Sir Knight. Sit down for a change."],
	},
	"Ada Thorne": {
		"ch1": ["My husband's a guard at the castle. Nights, mostly. He says it's quiet. Too quiet, he says. He says that every night."],
		"peace": ["He came home. He was at the castle when it fell, and he came home. I don't know how. I don't care how."],
		"ch5": ["He's training the new recruits now. Every time one of them comes home safe, he comes home happier."],
		"end": ["We're going to the feast together. First time in years he's not been on duty. He doesn't know what to do with his hands."],
	},
	"Watchman Edric": {
		"ch1": ["Night watch on the walls. Last night I saw a light in the far east, like a fire under the horizon. The seer was screaming before dawn."],
		"peace": ["I watched the Citadel burn from the walls. Then I watched the light go out. That was a good night to be on watch."],
		"ch5": ["I saw the sky crack, over the Ridge, far in the west. Like ice on a pond. Sorry. I can't stop thinking about it."],
		"end": ["I watched it close. From the wall. The crack, closing up, and all the stars coming back out behind it. Best watch of my life."],
	},
	"Lucette": {
		"ch1": ["Glass from the furnace! Bottles for potions, beads for the market, and very tiny swans. Mind the tiny swans."],
		"peace": ["All my glass melted in the fire. Melted into one big lump. I kept the lump. I'm calling it art."],
		"ch5": ["Bottles for the knights' march! Strong ones. Black water won't get in them. I hope."],
		"end": ["I'm making a window for the chapel. Colored glass. A knight and a goddess and a sky full of stars. It'll take a year. It'll be worth it."],
	},
	# --- Haven Village -------------------------------------------------------
	"Mother Thatcher": {
		"ch1": ["Morning, Sir Gigglebuns! Up early for once. Robin, say good morning to Sir Gigglebuns. ROBIN."],
		"fallen": ["We've a family from Castle Town in the back room. Lovely people. Snore like dragons."],
		"war": ["Rowena wants every man and woman who can hold a pitchfork on the palisade tonight. I can hold a pitchfork. I can hold two."],
		"peace": ["We grew the village a whole new row of houses for the Ashwick folk. They've brought their own songs. Sad ones, mostly. We're teaching them happy ones."],
		"ch5": ["Robin's off with the knights now. A squire! My Robin! I made him take an extra scarf."],
		"end": ["Robin wrote from the Ridge: he saw the sky close. He says he cried. He says not to tell anyone. I'm telling everyone."],
	},
	"Robin Thatcher": {
		"ch1": ["Mom says I can be a knight if I eat my turnips. I've eaten so many turnips."],
		"war": ["I'm on the palisade tonight! With a sling! Mom doesn't know. Don't tell Mom."],
		"peace": ["I got a medal for the siege! It's a button. Rowena gave it to me. It's a very important button."],
	},
	"Old Bartholomew": {
		"ch1": ["Eh? The castle's page ran past here at dawn like his pants were on fire. Something's afoot. Something's always afoot. My foot, mostly."],
		"fallen": ["Castle Town's people are everywhere. In my garden. In my well. One of them is in my chair right now. Look. LOOK."],
		"war": ["Goblins! In my day goblins knew their place. Under bridges. Not coming up the road with ladders."],
		"peace": ["Peace and quiet at last. Except for those Ashwick folk singing. Actually, they're not bad. Don't tell them I said so."],
		"ch5": ["I'm older than the castle walls now. Older than the new ones, anyway. Still sharp. What were we talking about?"],
		"end": ["Peace! Good. Now everybody get off my lawn. Except you, Sir Knight. You can stay on my lawn."],
	},
	"Weaver Gwen": {
		"ch1": ["The loom's been in my family for six generations. The cloth's been in my family for about a week. I sell it fast."],
		"war": ["I'm weaving bandages now. Nothing but bandages. Hundreds. I hope we need none of them."],
		"peace": ["The Ashwick weavers taught me Batela patterns. Fire and ash. Gray and red. Beautiful and sad."],
		"ch5": ["Banners for the knights! Haven blue, every one. I could weave Haven blue in my sleep. I have, actually."],
		"end": ["I'm weaving a tapestry of the whole thing. Every chapter. It's going to be very long. You'll be in most of it."],
	},
	"Fisher Abel": {
		"ch1": ["The river's good this time of year. Mira at the lake says the big one's still out there. The Lake's Legend. Nobody's ever landed it."],
		"war": ["Too dangerous to fish with goblins about. I've been fishing in a bucket. I caught a frog. I let him go."],
		"peace": ["Back on the river. The water's sweet again. The fish came back before the people did."],
		"ch5": ["I took the boy to Mirror Lake. Mira gave him a rod. He caught a fish bigger than him. He talks of nothing else."],
		"end": ["I'm going to go fishing for a week. A whole week. Don't look for me. I'll be at the lake, being happy."],
	},
	"Granny Pell": {
		"ch1": ["Your grandmother and I were girls together, you know. She'd be proud of you. Then she'd tell you to stand up straight."],
		"fallen": ["Poor Castle Town. I've baked so many pies for the refugees my arms have gone stiff. Worth it."],
		"war": ["They say the Questlords are holding out at Westmarch, west of the field. Brave girls. Foolish, but brave."],
		"peace": ["The war's over and I'm still baking pies. I don't know how to stop now. Here. Have a pie."],
		"ch5": ["A knight! Your grandmother would have burst. Then she'd have told you to stand up straight. Stand up straight."],
		"end": ["I lit a candle for your grandmother tonight. I told her all about it. She'd say you took your time."],
	},
	"Dot": {
		"ch1": ["We're twins! I'm the older one. By four minutes. Dash says that doesn't count. It counts."],
		"war": ["We're hiding under the bed until the siege is over. Mom says. It's pretty nice under the bed. We have cookies."],
		"peace": ["We saw the Questlords ride in after Westmarch! Idrith waved at me! At ME! Dash says she waved at him. She waved at me."],
		"ch5": ["We're old enough to go to the market by ourselves now. We went. We came back. It was very exciting."],
		"end": ["When the sky closed, everyone cheered so loud Dash fell off the fence. He's fine. He's always fine."],
	},
	"Dash": {
		"ch1": ["Dot's always going on about being four minutes older. In four minutes I'll be as old as she is now. Think about it."],
		"war": ["I'm not scared of goblins. I'm not. I'm under the bed because I dropped a cookie."],
		"peace": ["Idrith waved at ME. Dot's wrong. Dot's always wrong. By four minutes."],
		"ch5": ["I'm going to be a Questlord when I grow up. Aladriel says I have to learn to sit very still first. That's the hard part."],
		"end": ["I fell off the fence but I didn't cry. Much. It was a very good fence to fall off."],
	},
	# --- Ashwick --------------------------------------------------------------
	"Corin": {
		"ch1": ["Welcome to my tent. All of it. That's it. That's the whole tent."],
		"war": ["Haven's at war now, they say. Strange, being the ones who are safe for once."],
		"peace": ["Most of us are going to Haven. I'm staying. Someone has to keep the graves. Someone has to remember."],
		"ch5": ["I'm still here. The Fells are coming back, slowly. Green at the edges. I planted most of it."],
		"end": ["I'm going to build a proper house. With walls. Ashwick will be a real village again. You'll visit?"],
	},
	"Healer Brisa": {
		"ch1": ["Sit down, let me look at you. Ash in the lungs, ash in the eyes. Everyone out here has it. Drink this. Don't ask what it is."],
		"war": ["They say the war's reached Haven. Our turn to send help. I'm packing every herb I own."],
		"peace": ["I'm going to Haven with the others. Hazel at Castle Town wants to learn the Batela remedies. We'll trade secrets."],
		"ch5": ["I came back to the Fells. The air's clearer now. I can grow the herbs again."],
		"end": ["No more burns to treat. I don't know what to do with myself. I'm going to grow flowers instead. Just for looking at."],
	},
	"Old Guard Varn": {
		"ch1": ["I served Firebuns. The third one. Before. He was a good king once, you know. Before they poisoned him. Before whatever came back."],
		"war": ["I knew him. I knew him when he laughed at feasts and remembered every soldier's name. I don't know who that is, burning your country."],
		"peace": ["Frozen, they say. Sealed away. ...I hope wherever he is, some part of him is sleeping."],
		"ch5": ["Back again. He came back. Of course he came back. He never could stay down. Even when we wanted him to."],
		"end": ["Gone for good, then. ...Thank you, Sir Knight. For him too. I think, at the end, he'd thank you as well."],
	},
}

const ORDER := ["ch1", "fallen", "war", "peace", "ch5", "end"]


static func era() -> String:
	if Progress.flag("ch5:firebuns_end") or Progress.flag("game_complete"):
		return "end"
	if Progress.flag("ch5:knight"):
		return "ch5"
	if Progress.flag("ch4:peace"):
		return "peace"
	if Progress.flag("ch4:war"):
		return "war"
	if Progress.flag("castle_fallen"):
		return "fallen"
	return "ch1"


## The lines for `who` in era `e`, or the nearest earlier era they have.
static func for_era(who: String, e: String) -> Array:
	var l: Dictionary = LINES.get(who, {})
	var i := ORDER.find(e)
	while i >= 0:
		if l.has(ORDER[i]):
			return l[ORDER[i]]
		i -= 1
	for k in ORDER:
		if l.has(k):
			return l[k]
	return []


static func lines(npc: Node) -> Array:
	var who := String(npc.npc_name)
	var own := for_era(who, era())
	if own.is_empty():
		return [Gossip.rumor()]
	# Every other time (the second, the fourth...): the talk of the day.
	if int(npc.get("talks")) % 2 == 1:
		return [Gossip.rumor()]
	var out: Array = []
	for t in own:
		out.append({"text": String(t), "anim": "happy" if era() == "end" else "talk"})
	return out
