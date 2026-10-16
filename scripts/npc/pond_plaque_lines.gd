extends RefCounted
## The gilt plaque on the rim of Himeko's pond: before the hero brings her a
## fish it waits for a royal resident; after, it names him (Himeko named him
## herself, and it shows).


static func lines(_ex: Node) -> Array:
	if not Progress.flag("himeko:fish_given"):
		return [{"text": "A gilt plaque on the rim of the pond:\n*RESERVED FOR THE ROYAL FISH*\n(Applications to the Princess.)", "instant": true}]
	return [
		{"text": "A gilt plaque on the rim of the pond:\n*HIS GRACE LORD BUBBLES THE MAGNIFICENT*\n*Duke of the Pond, Baron of the Lily Pad*", "instant": true},
		{"text": "Underneath, in smaller letters:\n*Rescued from a bottle by Sir Gigglebuns IV, Knight of the Princess.*\n*Do not tap the water. He is sleeping.*", "instant": true},
	]
