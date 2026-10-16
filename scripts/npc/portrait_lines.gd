extends RefCounted
## The three portraits on the north wall of the hero's house: Gigglebuns I,
## II and III, the knights of his line (Lothelye names them in the legend).
## Each Examine's `key` is "1", "2" or "3". After the legend, each adds a
## line the hero now understands.


static func lines(ex: Node) -> Array:
	var told := Progress.flag("legend_told")
	match String(ex.get("key")):
		"1":
			var p: Array = [{"text": "*Sir Gigglebuns I*\nHe wears a golden circlet and looks very serious about it.", "instant": true},
				{"text": "The family story goes that he once ate an entire banquet bun by himself to keep it from a troll.", "instant": true}]
			if told:
				p.append({"text": "Lothelye said the first of the line stood against the dark. He still looks serious about the bun.", "instant": true})
			return p
		"2":
			var p2: Array = [{"text": "*Sir Gigglebuns II*\nHe has a magnificent brown mustache and is pointing at something off the edge of the frame.", "instant": true},
				{"text": "Nobody in the family knows what he is pointing at. It has been argued about at every dinner for sixty years.", "instant": true}]
			if told:
				p2.append({"text": "...Maybe it was the Hidden Forest.", "instant": true})
			return p2
		"3":
			var p3: Array = [{"text": "*Sir Gigglebuns III*\nA kind face with white hair. Under the frame someone has carved a little bun.", "instant": true},
				{"text": "He fought the first Firebuns, they say, and came home, and planted the apple tree in the village.", "instant": true}]
			if Progress.flag("game_beaten"):
				p3.append({"text": "He came home from his war. So will you.", "instant": true})
			return p3
	return []
