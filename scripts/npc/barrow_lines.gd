class_name BarrowLines
extends RefCounted
## What the Barrow of Kings says (Chapter V): the seven kings' epitaphs (each
## read sets "barrow:epitaph_<n>"; the JOURNAL keeps them on THE KINGS OF
## HAVEN page), the doors and the seals. Once all seven are read the tombs
## answer one another and the kings' vault behind the hall of crowns opens
## ("barrow:kings_vault_open"; its chest sets "barrow:kings_vault").

## In the order of their tombs, oldest first: [name, epitaph].
const KINGS := [
	["ALDRIC I, THE FIRST STONE", "He laid the Citadel's first stone with his own hands, and his hands are in it still."],
	["OSWIN THE WARDEN", "He chained Caoimhe, the Lady of War, beneath the hills, and did not sleep again until this sleep."],
	["EDMUND THE BUILDER", "Northwatch, Eastgate, Westmarch: three fortresses, that Haven might sleep sound."],
	["QUEEN DOT", "She rode beside Gigglebuns III and took back the Castle of Haven from the Evil King. She laughed like a bell."],
	["ROWAN THE GENTLE", "In forty years he never drew his sword. He never needed to."],
	["HARROW, THE HOLLOW KING", "(The name is scratched away. Beneath it, in a rougher hand:) He bargained with the dark for a crown that would never fall. It never did. Nor did he."],
	["CORVIN THE YOUNG", "He was king for one winter only, and gave his cloak away every night of it."],
]
const VAULT := "barrow:kings_vault_open"


static func flag_of(n: int) -> String:
	return "barrow:epitaph_%d" % n


## How many epitaphs have been read.
static func read() -> int:
	var c := 0
	for i in KINGS.size():
		if Progress.flag(flag_of(i + 1)):
			c += 1
	return c


## The journal's lines: each read epitaph's king.
static func journal_lines() -> Array:
	var out: Array = []
	for i in KINGS.size():
		if Progress.flag(flag_of(i + 1)):
			out.append(String(KINGS[i][0]))
	return out


static func lines(ex: Node) -> Array:
	var key := String(ex.get("key"))
	if key.begins_with("epitaph_"):
		return _epitaph(int(key.trim_prefix("epitaph_")))
	match key:
		"stair":
			return [{"text": "Carved over the stair down, in letters worn almost flat:\n*HERE SLEEP THE KINGS OF HAVEN. WAKE THEM NOT.*\nSomeone has woken them.", "instant": true}]
		"seals":
			return [{"text": "The floor here is a great seal of cracked stone, set with an iron crown. It rings hollow underfoot.\n*ONLY A BLOW FROM ABOVE BREAKS WHAT THE KINGS SEALED.*", "instant": true}]
		"bells":
			return [{"text": "Four bronze bells hang in a ring round a worn circle in the floor. A verse under them:\n*STRIKE ONE AND ONE WILL ANSWER. STRIKE ALL AT ONCE, AND THE DEAD WILL LISTEN.*", "instant": true}]
		"knights":
			return [{"text": "Effigies of the kings' sworn knights line the walls, every one with its shield up.\n*THEY GUARD STILL. NO BLADE PASSES THEIR SHIELDS; A SHIELD MAY.*", "instant": true}]
		"stones":
			return [{"text": "Two great stones close the passage, too big for any arms to lift.\n*THE QUESTLORDS DRAGGED THEM HERE. ONLY A QUESTLORD'S GRIP WILL MOVE THEM.*", "instant": true}]
		"crowns":
			if Progress.flag(VAULT):
				return [{"text": "The seven crowns over the tombs are lit, and the wall behind them stands open.", "instant": true}]
			return [{"text": "Seven empty niches for seven crowns, over a blank stretch of wall.\n*READ THE KINGS, EACH ONE, AND THEY WILL OPEN WHAT THEY KEPT TOGETHER.*\n(%d of 7 read.)" % read(), "instant": true}]
	return ["..."]


static func _epitaph(n: int) -> Array:
	if n < 1 or n > KINGS.size():
		return ["..."]
	var k: Array = KINGS[n - 1]
	var fresh := not Progress.flag(flag_of(n))
	Progress.set_flag(flag_of(n))
	var pages: Array = [{"text": "A king's tomb, the effigy's hands folded on a stone sword. Cut into its side:\n*%s*" % String(k[0]), "instant": true},
		{"text": String(k[1]), "instant": true}]
	if fresh:
		Sfx.play("secret", -8.0)
		if read() >= KINGS.size() and not Progress.flag(VAULT):
			Progress.set_flag(VAULT)
			pages.append({"text": "Somewhere in the Barrow, stone grinds on stone. All seven kings have been read... and the tombs are *answering one another*.", "instant": true})
		else:
			pages.append({"text": "(The epitaph is written in your Journal: *THE KINGS OF HAVEN*, %d of 7.)" % read(), "instant": true})
	return pages
