extends RefCounted
## The Sun Trial's sanctum: the empty pedestal where the Sunstone lay, and a
## map the Order left behind in their hurry. Reading it finds the Gauntlet's
## trail ("ch2:trail_found"), the end of Chapter II: Chapter III's card follows.


static func lines(ex: Node) -> Array:
	if String(ex.get("key")) == "pedestal":
		return [
			"An empty pedestal, ringed with scorch marks. Something burning hot was lifted off it, not long ago.",
			"The *Sunstone* is gone. The Order got here first.",
		]
	var first := not Progress.flag("ch2:trail_found")
	Progress.set_flag("sun_trial:done")
	Progress.set_flag("ch2:trail_found")
	var pages: Array = [
		"A map of Bunsriel, half burnt, dropped in a hurry. A line of red ink runs east out of Haven, across the Desert of Ladhellin...",
		"...past the edge of the map, to the *Batela Fells*: Firebuns' own homeland, the land he burned.",
		"Beside it, in a careful hand: *Feed the Gauntlet. Open the way. Wake the Dark Lord.*",
		"A dotted line runs through the *Eternal Sandstorm* east of the desert, with a note: *The old Batela road lies under the storm. Walk into the wind, and do not stop.*",
	]
	if first:
		# Chapter III begins: its card once the map is folded away.
		pages.append({"text": "The Gauntlet's trail leads east, through the sandstorm. As you fold the map, the wind out in the desert drops, all at once.", "chapter_card": 3})
	return pages
