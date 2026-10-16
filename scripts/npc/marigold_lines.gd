extends RefCounted
## What Marigold says. She keeps the general store in Haven Village: bubbly,
## a born saleswoman, forever baking. The goods on the counter are bought by
## walking up to them (ShopItem); she talks about them and the village.
##
## Pages follow the Dialogue format; "anim" picks her pose: talk, happy.

const MET := "marigold_met"


static func lines(npc: Node) -> Array:
	# The trade chain to the Questlord's Shield comes first when it's their turn.
	var trade: Array = TradeLines.lines_for("Marigold", npc) if Progress.flag(MET) else []
	if not trade.is_empty():
		return trade
	if not Progress.flag(MET):
		Progress.set_flag(MET)
		return [
			{"text": "Welcome, welcome! *Marigold's Goods*, finest shop in Haven Village! ...Also the only shop in Haven Village.", "anim": "happy"},
			{"text": "Look over anything on the counter. Walk up to it and press *A* to check the price. I'll ring you up!", "anim": "talk"},
		]
	var chats := [
		{"text": "Arrows, hearts, a nice big quiver... and honey buns! Idrith gave me her recipe. Don't tell anyone.", "anim": "talk"},
		{"text": "*Bombs*! Brand new stock. Great for cracked walls and old boulders. Not great for indoors. Please buy them OUTSIDE of my shop!", "anim": "happy"},
		{"text": "Short on Coins? Cut some grass, break some pots. ...Not MY pots, please.", "anim": "talk"},
		{"text": "Pink in Old Castle Town makes swords. She used to give them away! I told her she'd go broke, and now she charges. You're welcome!", "anim": "happy"},
		{"text": "Ottilie at the library wants her cookbook back. I'm still using it! There's only a little flour on it.", "anim": "talk"},
	]
	return [chats[(npc.talks - 1) % chats.size()]]


static func on_event(_npc: Node, _ev: String) -> void:
	pass
