class_name HouseData
extends RefCounted
## The houses you can walk into (Beta 1.5.0): Castle Town's homes and shops,
## Haven Village's cottages and Ashwick's tents. Shared by the runtime
## (WorldData looks here for an area's title and parent) and the generator
## (tools/world/regions/house_interior.gd builds each interior from its
## entry; scripts/npc/house_lines.gd has what the people inside say).
##
## Each house: title, parent (the area outside, by its link name), kind (the
## furniture: home, bakery, tailor, grocer, scholar, inn, workshop, shop,
## apothecary, chandler, tent), wall color, and folk: [name, model, show
## flag, hide flag]. Castle Town's houses are numbered in the order its
## street rows are built (castle_town.gd _row); CT_DOORS says which of the
## 42 facades open.

const KINDS := ["home", "bakery", "tailor", "grocer", "scholar", "inn", "workshop", "shop", "apothecary", "chandler", "tent"]

const HOUSES := {
	# Castle Town (castle_town.gd: houses along the streets, in build order).
	"ct_00": {"title": "THE BRIGHTWATER HOUSE", "parent": "castle_town", "kind": "home", "wall": "f0e0c8", "folk": [["Nell Brightwater", "folk_washer", "", ""]]},
	"ct_01": {"title": "BETTANY'S BAKERY", "parent": "castle_town", "kind": "bakery", "wall": "f4e4c4", "folk": [["Bettany", "folk_baker", "", ""]]},
	"ct_02": {"title": "OLD TOBIAS'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "e8d8c0", "folk": [["Old Tobias", "folk_elder", "", ""]]},
	"ct_03": {"title": "FENWICK'S FINE CLOTH", "parent": "castle_town", "kind": "tailor", "wall": "e8d0e0", "folk": [["Fenwick", "folk_tailor", "", ""]]},
	"ct_04": {"title": "THE PENNYROYAL HOUSE", "parent": "castle_town", "kind": "home", "wall": "e0e8d0", "folk": [["Wick", "folk_boy", "", ""], ["Lark", "folk_girl", "", ""]]},
	"ct_05": {"title": "GARTH'S GREENS", "parent": "castle_town", "kind": "grocer", "wall": "e0ecc8", "folk": [["Garth", "folk_grocer", "", ""]]},
	"ct_06": {"title": "MASTER QUILL, CARTOGRAPHER", "parent": "castle_town", "kind": "scholar", "wall": "d8dcf0", "folk": [["Master Quill", "folk_scholar", "", ""]]},
	"ct_07": {"title": "GRANNY FENNEL'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "f0e4d8", "folk": [["Granny Fennel", "folk_granny", "", ""]]},
	"ct_08": {"title": "THE GOLDEN BUN", "parent": "castle_town", "kind": "inn", "wall": "e8c890", "music": "tavern", "folk": [
		["Rosalind", "folk_innkeeper", "", ""], ["Lute Player", "folk_bard_lute", "", ""], ["Drummer", "folk_bard_drum", "", ""], ["Fiddler", "folk_bard_fiddle", "", ""]]},
	"ct_09": {"title": "CAPTAIN OSTRIN'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "d8d8e0", "folk": [["Captain Ostrin", "haven_soldier", "", ""]]},
	"ct_10": {"title": "SILAS GOLDTHREAD, MERCHANT", "parent": "castle_town", "kind": "shop", "wall": "f0d8a8", "folk": [["Silas Goldthread", "folk_merchant", "", ""]]},
	"ct_11": {"title": "DUNSTAN'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "c8d8e8", "folk": [["Dunstan", "folk_fisher", "", ""]]},
	"ct_12": {"title": "THE MEADOWS HOUSE", "parent": "castle_town", "kind": "home", "wall": "e8e0b8", "folk": [["Mabel Meadows", "folk_farmer", "", ""]]},
	"ct_13": {"title": "PIM'S TOYS", "parent": "castle_town", "kind": "workshop", "wall": "f0d0b0", "folk": [["Pim the Toymaker", "folk_tailor", "", ""]]},
	"ct_14": {"title": "SISTER AGNES'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "f0f0f0", "folk": [["Sister Agnes", "folk_granny", "", ""]]},
	"ct_15": {"title": "WAX AND WICK", "parent": "castle_town", "kind": "chandler", "wall": "f0e8c0", "folk": [["Clemence", "folk_washer", "", ""]]},
	"ct_16": {"title": "BRAM THE COOPER", "parent": "castle_town", "kind": "workshop", "wall": "d8c0a0", "folk": [["Bram", "folk_grocer", "", ""]]},
	"ct_17": {"title": "HAZEL'S REMEDIES", "parent": "castle_town", "kind": "apothecary", "wall": "d0e8d0", "folk": [["Hazel", "folk_innkeeper", "", ""]]},
	"ct_18": {"title": "THE NEWLYWEDS' HOUSE", "parent": "castle_town", "kind": "home", "wall": "f0d8d8", "folk": [["Rowan", "folk_fisher", "", ""], ["Ivy", "folk_farmer", "", ""]]},
	"ct_19": {"title": "OLD SERGEANT HOLT'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "c8ccd8", "folk": [["Sergeant Holt", "folk_elder", "", ""]]},
	"ct_20": {"title": "THE BOOKBINDER", "parent": "castle_town", "kind": "scholar", "wall": "e0d8c8", "folk": [["Odo the Bookbinder", "folk_scholar", "", ""]]},
	"ct_21": {"title": "AN EMPTY HOUSE", "parent": "castle_town", "kind": "home", "wall": "d8d0c8", "folk": [["Tansy's Cousin", "folk_girl", "ch5:knight", ""]]},
	"ct_22": {"title": "THE FIDDLER'S ROOMS", "parent": "castle_town", "kind": "home", "wall": "d8f0e0", "folk": [["Melody", "folk_bard_fiddle", "", ""]]},
	"ct_23": {"title": "WIDOW PURRINGTON'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "f0e0f0", "folk": [["Widow Purrington", "folk_granny", "", ""]]},
	"ct_24": {"title": "THE COBBLER", "parent": "castle_town", "kind": "workshop", "wall": "e0c8b0", "folk": [["Cobbler Jory", "folk_tailor", "", ""]]},
	"ct_25": {"title": "THE THORNE HOUSE", "parent": "castle_town", "kind": "home", "wall": "e8e8d0", "folk": [["Ada Thorne", "folk_farmer", "", ""]]},
	"ct_26": {"title": "THE WATCHMAN'S HOUSE", "parent": "castle_town", "kind": "home", "wall": "d0d8e8", "folk": [["Watchman Edric", "haven_soldier", "", ""]]},
	"ct_27": {"title": "THE GLASSBLOWER", "parent": "castle_town", "kind": "shop", "wall": "d8f0f0", "folk": [["Lucette", "folk_innkeeper", "", ""]]},
	# Haven Village's cottages (village.gd).
	"hv_1": {"title": "THE THATCHER COTTAGE", "parent": "village", "kind": "home", "wall": "f0e0c0", "folk": [["Mother Thatcher", "folk_farmer", "", ""], ["Robin Thatcher", "folk_boy", "", ""]]},
	"hv_2": {"title": "OLD BARTHOLOMEW'S COTTAGE", "parent": "village", "kind": "home", "wall": "e8dcc8", "folk": [["Old Bartholomew", "folk_elder", "", ""]]},
	"hv_3": {"title": "THE WEAVER'S COTTAGE", "parent": "village", "kind": "tailor", "wall": "e0d8f0", "folk": [["Weaver Gwen", "folk_washer", "", ""]]},
	"hv_4": {"title": "THE FISHER'S COTTAGE", "parent": "village", "kind": "home", "wall": "d0e0f0", "folk": [["Fisher Abel", "folk_fisher", "", ""]]},
	"hv_5": {"title": "GRANNY PELL'S COTTAGE", "parent": "village", "kind": "home", "wall": "f0e8e0", "folk": [["Granny Pell", "folk_granny", "", ""]]},
	"hv_6": {"title": "THE TWINS' COTTAGE", "parent": "village", "kind": "home", "wall": "e8f0d8", "folk": [["Dot", "folk_girl", "", ""], ["Dash", "folk_boy", "", ""]]},
	# Ashwick's tents (batela_fells.gd, the survivors' camp).
	"aw_1": {"title": "A TENT IN ASHWICK", "parent": "batela_fells", "kind": "tent", "wall": "8a8070", "folk": [["Corin", "folk_ashwick_a", "", ""]]},
	"aw_2": {"title": "THE HEALER'S TENT", "parent": "batela_fells", "kind": "tent", "wall": "8a7a6a", "folk": [["Healer Brisa", "folk_ashwick_b", "", ""]]},
	"aw_3": {"title": "THE OLD GUARD'S TENT", "parent": "batela_fells", "kind": "tent", "wall": "7a7468", "folk": [["Old Guard Varn", "folk_ashwick_a", "", ""]]},
}

## Which of Castle Town's 42 street facades open (two of every three).
static func ct_door(n: int) -> String:
	if n % 3 == 2:
		return ""
	var i := n - n / 3
	var id := "ct_%02d" % i
	return id if HOUSES.has(id) else ""


static func has(area: String) -> bool:
	return HOUSES.has(area)


static func data(area: String) -> Dictionary:
	var h: Dictionary = HOUSES.get(area, {})
	if h.is_empty():
		return {}
	var out := {"title": h.title, "interior": true, "parent": h.parent, "ambience": "amb_hearth"}
	if h.has("music"):
		out["music"] = h.music
	return out
