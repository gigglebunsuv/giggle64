class_name IncunabulumLines
extends RefCounted
## The five lost pages of the Fari Incunabulum, the forbidden tome the
## Sapphire Order studies under the Batela Fells (lore, Saga 0). Each is read
## when found (GetItem "incunabulum_page_<n>") and kept in the JOURNAL.
## What they tell, in order: the Astral prison, the soul-bargain that kept
## Firebuns III alive, the one light the Gauntlet cannot rule, how a sealed
## door is opened, and the goddess who unmade Denangdyn once.

const COUNT := 5
const TITLES := {
	1: "OF THE PRISON OF STARS",
	2: "OF BARGAINS FOR A SOUL",
	3: "OF THE GAUNTLET OF FIRE",
	4: "OF DOORS AND THEIR SIDES",
	5: "OF THE ONE WHO UNMAKES",
}
const PAGES := {
	1: ["\"...and the Dreamer made a dimension of stars to hold what could not be killed, and set him there, and the door of it has no lock on the inside...\""],
	2: ["\"...a soul given in bargain is kept, not spent. Let the vessel die, by blade or by poison, and the soul waits in the dark like a coal under ash, until it is called back...\""],
	3: ["\"...it commands every flame in Bunsriel, the hearth and the pyre and the mountain's heart. Only the cold light of the stars does not kneel to it, for that light was the Dreamer's before fire was made...\""],
	4: ["\"...a door is opened from both sides. Let one push from the world of the living, and one pull from the prison, and the seal will crack like ice in spring...\""],
	5: ["\"...and should he wake, she will come again, she who unmade him once in a single breath: the Goddess of Destruction, who keeps the balance. Pray that she is kind.\""],
}


static func flag_of(n: int) -> String:
	return "incunabulum:%d" % n


static func found() -> int:
	var n := 0
	for i in range(1, COUNT + 1):
		if Progress.flag(flag_of(i)):
			n += 1
	return n
