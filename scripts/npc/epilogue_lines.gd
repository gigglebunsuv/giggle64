class_name EpilogueLines
extends RefCounted
## After the true ending (Beta 1.5.0): what the people you know say about it.
## Npc.interact asks here first once Firebuns III is gone ("ch5:firebuns_end"),
## every other time you speak to them (the rest of the time they are their
## usual selves, so their own lines and errands still work).

const LINES := {
	"Mira": ["You're back! I watched the sky over the lake all night. When the stars came out again, every single one, I knew. Come fishing tomorrow. Bring nothing. Just come."],
	"Himeko": ["The princess of Haven Village declares a holiday! For a week! ...For a month. I'll have to ask the King if I'm allowed to do that. I'm doing it anyway."],
	"Pink": ["Look at that blade. Not a nick in it, after all that. I'll polish it anyway. A sword like that deserves to shine at the feast."],
	"Aladriel": ["So it is finished. ...Sit with me a while, Knight. Idrith wants to tell the story of it. I want to hear it from you first."],
	"Idrith": ["We Questlords have a word for a deed that ends a war: *last-light*. No one has earned it in a hundred years. You have."],
	"Ottilie": ["I'm writing it all down. Every word. One day someone will come to this library and ask how it ended, and I'll hand them a very, very thick book."],
	"Marigold": ["Business is booming, and for once it's not swords and bombs! Bunting! Lanterns! Cake tins! Peace is GOOD for trade, Sir Knight!"],
	"Clover": ["Gran always said that horseshoe was lucky. I didn't believe her. I think I believe her now."],
	"Hilde": ["Up on the mountain the snow sparkled like stars, the night it ended. I made a hot drink for everyone in the hut. Even the goats."],
	"Tansy": ["A free round of cups, Sir Knight, for saving the world! ...You still have to win it, mind."],
	"Posy": ["Pepper barked at the sky all night when it closed up! Then she slept for a whole day. She's a hero too. A tired one."],
	"Maud": ["He's gone, then. Truly. ...I wronged him once, long ago, and he paid it back a hundredfold. I hope there's a quiet place for him now. I hope he's warm."],
	"Wren": ["I'll dig no more graves for that war. Thank you, Knight. I'd almost forgotten what it's like to bury only the old and the peaceful."],
	"Odile": ["We're going home to the Fells. To build Ashwick properly this time. Walls. A well. A bell tower that rings for weddings."],
	"Tamsin": ["Elder Maud cried and then she laughed and then she cried again. Grown-ups are confusing. I'm glad you won though."],
	"Commander Rowena": ["Knight. ...Gigglebuns. You did it. I'll be giving speeches about this for the rest of my life. I'll make you sound taller."],
	"Captain Rowena": ["Knight. ...Gigglebuns. You did it. I'll be giving speeches about this for the rest of my life. I'll make you sound taller."],
	"Gate Guard": ["Quietest watch I've ever stood. Nothing coming up the road but carts of flowers for the feast. I could get used to this."],
	"Camp Sentry": ["The Ridge is just a ridge now. Black rocks and white water. I watched the sky close from up here. I'll never forget it."],
	"Sir Brannoc": ["We won! I'm going swimming. In every lake. All of them. Clear water, every one."],
	"Dame Elsabet": ["The banner in the square has a new line on it now. Not a name. Just: *THEY HELD, AND IT WAS ENOUGH.*"],
	"Quartermaster": ["No more marching rations! I'm cooking a real stew tonight. With meat in it. Mostly."],
	"Squire": ["I want to be a knight just like you, Sir. Commander Rowena says I have to learn to stand still first."],
	"Haven Folk": ["There's dancing in the square tonight. You'll come, Sir Knight? Everyone wants to dance with the hero. Nobody's very good."],
}


## The epilogue's word for `npc` this time, or [] to let them speak as usual.
static func lines(npc: Node) -> Array:
	if not Progress.flag("ch5:firebuns_end"):
		return []
	var l: Array = LINES.get(String(npc.npc_name), [])
	if l.is_empty() or int(npc.get("talks")) % 2 == 1:
		return []
	var out: Array = []
	for t in l:
		out.append({"text": String(t), "anim": "happy"})
	return out
