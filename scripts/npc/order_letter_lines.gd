extends RefCounted
## The letter the Sapphire Order left in Frostpeak Hollow (an Examine by the
## serpent's pool, there once Sleetcoil is beaten): where they went next.
## Reading it sets "ch2:hollow_letter".


static func lines(_ex: Node) -> Array:
	Progress.set_flag("ch2:hollow_letter")
	return [
		"A letter, sealed with a blue gem. It reads:",
		"*To Lord Firebuns, from your servants of the Sapphire Order.*",
		"The Gauntlet's flame grows hungry, my lord. It drinks the cold of this mountain faster than we can feed it.",
		"The old texts speak of a *Sunstone*, kept in the *Trial of the Sun* beneath the sands of Ladhellin. Its fire never dies.",
		"We go to fetch it. The serpent will guard the way behind us. *Burn this letter.*",
		"...They didn't burn it. Aladriel will want to read this.",
	]
