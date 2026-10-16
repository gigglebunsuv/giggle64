extends RefCounted
## What the Temple of Bun's walls say (Chapter IV): the murals of Saga III,
## the pool of the trial, the tomb of the knights.

static func lines(ex: Node) -> Array:
	match String(ex.get("key")):
		"mural_1":
			return [
				{"text": "A mural in faded gold: a knight in red kneels before this very temple. Behind him walks a man with a crown of flame on his brow, his face kind.", "instant": true},
				{"text": "Under it: *GIGGLEBUNS III AND FIREBUNS II CAME TO THE GROVE TOGETHER, AND THE SWORD SLEPT IN THEIR KEEPING.*", "instant": true},
			]
		"mural_2":
			return [
				{"text": "A second mural: the same flame-crowned man stands alone against a black shape with burning eyes, his arms spread, and the shape is falling.", "instant": true},
				{"text": "*FIREBUNS II, WHO DIED A HERO, AND TOOK HIS FATHER WITH HIM.*\nSomeone has scratched a small flame beside his name. It looks like a prayer.", "instant": true},
			]
		"pool":
			return [{"text": "The pool is so still it might be glass. Carved round its rim:\n*THE SWORD WAKES ONLY FOR A HEART THAT IS PURE. FACE YOURSELF, AND DO WHAT YOU WOULD DO.*", "instant": true}]
		"tomb":
			return [{"text": "A knight's tomb, its effigy worn smooth by the centuries. The name is gone. Only the shape of a bun on the shield remains.", "instant": true}]
	return ["..."]
