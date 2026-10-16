extends RefCounted
## Things to Examine in the Batela Fells: the Firebuns portraits on the back
## wall of Batela Keep's great hall (lore, Sagas II to IV): Firebuns I, the
## Evil King; Firebuns II, who renounced him and died a hero beside
## Gigglebuns III; and the frame where Firebuns III's own portrait hung.


static func lines(ex: Node) -> Array:
	match String(ex.get("key")):
		"portrait_1":
			return [
				"A portrait, blackened at the edges. A king with a crown of flames and a cruel mouth. The plate reads: *FIREBUNS I, THE EVIL KING*.",
				"He raised an army of the dead against Haven's three fortresses, long ago. Gigglebuns III drove him back.",
			]
		"portrait_2":
			var p: Array = [
				"A portrait of a younger man in traveling clothes, almost smiling. The plate reads: *FIREBUNS II, OF EVRARGEST*.",
				"Under it, scratched into the stone by some loyal hand: *He turned from the fire. He died a hero.*",
			]
			if Progress.flag("ch3:keep_duel"):
				p.append("...He doesn't look anything like the one who just left you on the floor.")
			return p
		"portrait_3":
			return [
				"An empty frame. The canvas has been burned out of it, carefully, all the way to the edges.",
				"The plate is still there: *FIREBUNS III*.",
			]
	return []
