extends RefCounted
## The townsfolk of Beta 1.5.0 (the houses of Castle Town, Haven Village and
## Ashwick, the market, the tavern band, and Pip the castle page), built by
## one generic builder (gen_final_creatures._build_folk) with faces painted
## by gen_media._face_folk. Each spec:
##   id        model file (res://assets/models/<id>.tscn) and face "face_<id>"
##   skin      skin color; hair: hair color; eyes: iris color
##   style     hair: "short", "long", "bun", "pigtails", "bald", "tied"
##   hat       "" / "cap" (a page's cap with a feather) / "straw" / "felt" /
##             "kerchief" / "hood"
##   top       tunic/blouse color; trim: its collar and cuffs
##   bottom    "skirt" or "trousers"; legs: their color; shoes
##   apron     "" or an apron color
##   beard     "" / "full" / "mous" (mustache); lines: an older face
##   held      "" / "scroll" / "bread" / "lute" / "drum" / "fiddle" / "broom" / "cane" / "basket"
##   height    overall scale (children about 0.65)

const FOLK := [
	{"id": "pip", "skin": "f6d8c0", "hair": "c86a2a", "eyes": "3a7a4a", "style": "short", "hat": "cap",
		"top": "3048a8", "trim": "e8e8f0", "bottom": "trousers", "legs": "e8e4dc", "shoes": "5a3a22", "held": "scroll", "height": 0.86},
	{"id": "folk_baker", "skin": "f2d0b8", "hair": "6a3a22", "eyes": "5a3a22", "style": "bun", "hat": "kerchief",
		"top": "e8b860", "trim": "f8f0e0", "bottom": "skirt", "legs": "8a6a4a", "shoes": "4a3020", "apron": "f8f4ee", "held": "bread", "height": 1.0},
	{"id": "folk_grocer", "skin": "c89070", "hair": "2a1a14", "eyes": "3a2a1a", "style": "short", "hat": "felt",
		"top": "6a8a3a", "trim": "4a6a2a", "bottom": "trousers", "legs": "5a4a3a", "shoes": "3a2a1a", "apron": "e0d8c0", "beard": "mous", "height": 1.04},
	{"id": "folk_tailor", "skin": "f0d6c4", "hair": "8a8a92", "eyes": "4a5a8a", "style": "tied", "hat": "",
		"top": "8a3a6a", "trim": "e8c050", "bottom": "trousers", "legs": "3a3040", "shoes": "2a2028", "lines": true, "height": 0.98},
	{"id": "folk_elder", "skin": "e8c8b0", "hair": "d8d8dc", "eyes": "6a6a6a", "style": "bald", "hat": "",
		"top": "7a5a3a", "trim": "5a4028", "bottom": "skirt", "legs": "5a4028", "shoes": "3a2818", "beard": "full", "lines": true, "held": "cane", "height": 0.94},
	{"id": "folk_granny", "skin": "f0d4c0", "hair": "c8c8cc", "eyes": "5a6a7a", "style": "bun", "hat": "",
		"top": "5a6a9a", "trim": "e8e0d0", "bottom": "skirt", "legs": "4a5a7a", "shoes": "2a2a30", "lines": true, "held": "basket", "height": 0.9},
	{"id": "folk_girl", "skin": "f8dcc8", "hair": "3a2418", "eyes": "6a4a2a", "style": "pigtails", "hat": "",
		"top": "e86a8a", "trim": "f8f0f0", "bottom": "skirt", "legs": "f0e8e0", "shoes": "8a2a3a", "height": 0.64},
	{"id": "folk_boy", "skin": "d8a080", "hair": "1a1210", "eyes": "2a1a10", "style": "short", "hat": "felt",
		"top": "4a8ac8", "trim": "2a5a9a", "bottom": "trousers", "legs": "6a5a4a", "shoes": "3a2a1a", "height": 0.66},
	{"id": "folk_merchant", "skin": "f2d2be", "hair": "e0b040", "eyes": "3a6a9a", "style": "short", "hat": "felt",
		"top": "a82a2a", "trim": "e8c050", "bottom": "skirt", "legs": "6a1a1a", "shoes": "2a1a14", "beard": "full", "height": 1.08},
	{"id": "folk_innkeeper", "skin": "f4d6c2", "hair": "c84a2a", "eyes": "4a7a4a", "style": "long", "hat": "",
		"top": "3a6a5a", "trim": "f0e8d8", "bottom": "skirt", "legs": "2a4a40", "shoes": "3a2a20", "apron": "f0e8d8", "height": 1.0},
	{"id": "folk_fisher", "skin": "b8805a", "hair": "4a3a2a", "eyes": "3a4a5a", "style": "short", "hat": "straw",
		"top": "5a7a9a", "trim": "3a5a7a", "bottom": "trousers", "legs": "6a6050", "shoes": "3a3028", "beard": "full", "height": 1.02},
	{"id": "folk_farmer", "skin": "e8c0a0", "hair": "a86a3a", "eyes": "5a4a2a", "style": "tied", "hat": "straw",
		"top": "c8a050", "trim": "8a6a30", "bottom": "skirt", "legs": "6a5a3a", "shoes": "4a3a2a", "height": 0.98},
	{"id": "folk_scholar", "skin": "8a5a3e", "hair": "1a1414", "eyes": "2a1a14", "style": "short", "hat": "",
		"top": "2a3a6a", "trim": "c8b070", "bottom": "skirt", "legs": "1a2a4a", "shoes": "1a1a20", "beard": "mous", "held": "scroll", "height": 1.04},
	{"id": "folk_washer", "skin": "6a4030", "hair": "1a1210", "eyes": "2a1a10", "style": "bun", "hat": "kerchief",
		"top": "e8e0d0", "trim": "a83a3a", "bottom": "skirt", "legs": "8a3a3a", "shoes": "3a2018", "apron": "8ab8d8", "held": "broom", "height": 0.98},
	# The tavern band (the Golden Bun's stage).
	{"id": "folk_bard_lute", "skin": "f0d0b8", "hair": "1a1a1e", "eyes": "4a4a7a", "style": "long", "hat": "felt",
		"top": "6a2a8a", "trim": "e8c050", "bottom": "trousers", "legs": "2a2a3a", "shoes": "1a1a20", "held": "lute", "height": 1.0},
	{"id": "folk_bard_drum", "skin": "c88a6a", "hair": "6a2a1a", "eyes": "3a2a1a", "style": "tied", "hat": "",
		"top": "a8582a", "trim": "f0e0c0", "bottom": "trousers", "legs": "4a3a2a", "shoes": "2a1a14", "beard": "full", "held": "drum", "height": 1.06},
	{"id": "folk_bard_fiddle", "skin": "f8e0cc", "hair": "e8d080", "eyes": "4a8ac8", "style": "pigtails", "hat": "",
		"top": "2a7a5a", "trim": "f0f0e8", "bottom": "skirt", "legs": "1a4a3a", "shoes": "3a2a20", "held": "fiddle", "height": 0.98},
	# Ashwick's folk (the Batela survivors, gray with ash; later in Haven).
	{"id": "folk_ashwick_a", "skin": "e0c0a8", "hair": "5a5048", "eyes": "5a5a5a", "style": "short", "hat": "hood",
		"top": "6a645a", "trim": "4a443e", "bottom": "trousers", "legs": "4a443e", "shoes": "2a2620", "beard": "mous", "height": 1.0},
	{"id": "folk_ashwick_b", "skin": "c89878", "hair": "3a2a20", "eyes": "4a3a2a", "style": "long", "hat": "hood",
		"top": "7a6a5a", "trim": "5a4a3a", "bottom": "skirt", "legs": "4a3a2a", "shoes": "2a2018", "held": "basket", "height": 0.96},
]


static func ids() -> Array:
	var out: Array = []
	for f: Dictionary in FOLK:
		out.append(f.id)
	return out


static func find(id: String) -> Dictionary:
	for f: Dictionary in FOLK:
		if f.id == id:
			return f
	return {}
