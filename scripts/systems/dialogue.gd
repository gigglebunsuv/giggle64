extends Node
## Text boxes, after OoT's message system (z_message.c):
## - The box grows open over 8 frames using Message_GrowTextbox's width and
##   height coefficients, then the text types out one character per 20 Hz frame
##   (Message_DrawText advances textDrawPos once per frame at textDelay 0).
## - A or B while the text is typing shows the rest of the box at once
##   (sTextboxSkipped). When a box is complete a blinking triangle invites A for
##   the next box; the last box shows a square instead and A closes it.
## - A two- or three-choice box (TEXTBOX_ENDTYPE_2_CHOICE / _3_CHOICE) puts a
##   cursor beside the options: up and down move it, A decides.
##
## A script is an Array of pages. A page is a String, or a Dictionary:
##   {"text": String, "anim": StringName (speaker animation while it shows),
##    "choices": [[label, Array of pages], [label, Array of pages]]}
## Text wraps automatically; "\n" forces a break, and *stars* mark red words
## (OoT colors names and key words red). "instant": true shows a page whole at
## once (OoT's quick-text control code, used by signs).
##
## `style` picks the box: "black" (TEXTBOX_TYPE_BLACK, people) or "wooden"
## (TEXTBOX_TYPE_WOODEN, signs: brown wood at alpha 230, key words orange).
##
## `auto` plays the pages by themselves (the title screen's scenes, where
## nobody is holding the controller): each box stays up long enough to read
## (AUTO_HOLD plus AUTO_PER_CHAR a letter), then the next one types out. No
## button does anything, there is no triangle, and it runs on a paused tree.
## A page's "hold" (seconds) sets its own wait instead (scored cutscenes,
## which pace each box to the music).

signal finished
signal page_started(page: Dictionary)

enum Phase { CLOSED, OPENING, TYPING, WAITING, CHOOSING, CLOSING }

## Message_GrowTextbox's coefficients, one per 20 Hz frame.
const WIDTH_STEPS := [1.2, 1.5, 1.8, 2.0, 2.1, 2.2, 2.1, 2.0]
const HEIGHT_STEPS := [0.6, 0.75, 0.9, 1.0, 1.05, 1.1, 1.05, 1.0]
const FRAME := 1.0 / 20.0
const CHARS_PER_LINE := 38
const LINES_PER_BOX := 3
## Auto mode: seconds a finished box stays up, plus this much per letter.
const AUTO_HOLD := 1.4
const AUTO_PER_CHAR := 0.035

var phase := Phase.CLOSED
var speaker: Node = null
var style := "black"
## Queue of remaining pages (the current one first).
var _pages: Array = []
var page := {}
## Wrapped lines of the current page and the number of characters shown.
var lines: PackedStringArray = []
var shown := 0.0
var choice := 0
## The label of the last choice decided in this conversation ("" = none yet).
var last_choice := ""
## Animation clock in 20 Hz frames (box growth, blinking).
var timer := 0.0
var auto := false
var _total := 0
## The stick and d-pad for choices (MenuInput: a firm push, one axis).
var _choice_input := MenuInput.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


var active: bool:
	get: return phase != Phase.CLOSED


## Opens a conversation. `who` is the talking actor (its animation follows the pages).
func start(script: Array, who: Node = null, box_style := "black", auto_play := false) -> void:
	speaker = who
	style = box_style
	auto = auto_play
	process_mode = Node.PROCESS_MODE_ALWAYS if auto else Node.PROCESS_MODE_PAUSABLE
	last_choice = ""
	_pages = script.duplicate()
	phase = Phase.OPENING
	timer = 0.0
	Sfx.play("msg_open", -6.0)
	_load_page()


## Box size scale (width, height) during the opening animation, 1 when open.
func grow() -> Vector2:
	if phase != Phase.OPENING:
		return Vector2.ONE
	var i := clampi(int(timer), 0, WIDTH_STEPS.size() - 1)
	return Vector2(WIDTH_STEPS[i] / 2.0, HEIGHT_STEPS[i])


func visible_text(line: int) -> String:
	var before := 0
	for i in line:
		before += lines[i].length()
	return lines[line].substr(0, clampi(int(shown) - before, 0, lines[line].length()))


func is_last_page() -> bool:
	return _pages.size() <= 1 and not page.has("choices")


func _load_page() -> void:
	var p = _pages[0]
	page = p if p is Dictionary else {"text": String(p)}
	lines = wrap_text(String(page.get("text", "")))
	if lines.size() > LINES_PER_BOX and not page.has("choices"):
		_split_page()
	_total = 0
	for l in lines:
		_total += l.length()
	shown = _total if page.get("instant", false) else 0.0
	choice = 0
	page_started.emit(page)


## A page that wraps past LINES_PER_BOX keeps its first box and queues the rest
## as continuation pages. Those keep only the speaker keys (not events or anims),
## a red *span* cut by the break is closed and reopened, and a "hold" is shared
## out by length so scored scenes keep their timing.
func _split_page() -> void:
	var first := page.duplicate()
	var rest := {}
	for k in ["name", "actor", "instant"]:
		if page.has(k):
			rest[k] = page[k]
	var chunks: Array[String] = []
	for i in range(0, lines.size(), LINES_PER_BOX):
		chunks.append("\n".join(lines.slice(i, i + LINES_PER_BOX)))
	var red := false
	var total := 0
	for i in chunks.size():
		var c := chunks[i]
		if red:
			c = "*" + c
		if c.count("*") % 2 == 1:
			c += "*"
			red = true
		else:
			red = false
		chunks[i] = c
		total += c.replace("*", "").length()
	var pages := []
	for i in chunks.size():
		var d: Dictionary = first if i == 0 else rest.duplicate()
		d["text"] = chunks[i]
		if page.has("hold"):
			d["hold"] = float(page.hold) * chunks[i].replace("*", "").length() / maxf(1.0, total)
		pages.append(d)
	_pages.remove_at(0)
	_pages = pages + _pages
	page = _pages[0]
	lines = wrap_text(String(page.text))


## Greedy word wrap to CHARS_PER_LINE, honouring "\n". Star markers take no space.
static func wrap_text(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" ", false):
			var trial := word if line == "" else line + " " + word
			if trial.replace("*", "").length() > CHARS_PER_LINE and line != "":
				out.append(line)
				line = word
			else:
				line = trial
		out.append(line)
	return out


func _process(delta: float) -> void:
	if phase == Phase.CLOSED:
		return
	var frames := delta / FRAME
	timer += frames
	var a := Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept")
	var b := Input.is_action_just_pressed("attack")
	# Read every frame, so a stick already held when the choices come up does not count.
	var step := _choice_input.pressed().y
	if auto:
		a = false
		b = false
	# A skipped scene (Cutscene.skip) answers every box at once.
	if Cutscene.skipping:
		a = true
		timer = maxf(timer, float(WIDTH_STEPS.size()))
	match phase:
		Phase.OPENING:
			if timer >= WIDTH_STEPS.size():
				phase = Phase.TYPING
				timer = 0.0
		Phase.TYPING:
			shown += frames
			if a or b:
				shown = _total
			if shown >= _total:
				shown = _total
				phase = Phase.CHOOSING if page.has("choices") else Phase.WAITING
				timer = 0.0
		Phase.WAITING:
			if a or (auto and timer * FRAME >= auto_hold()):
				_advance()
		Phase.CHOOSING:
			var up := step < 0
			var down := step > 0
			if up or down:
				choice = wrapi(choice + (1 if down else -1), 0, page.choices.size())
				Sfx.play("menu_move", -8.0)
			if a:
				Sfx.play("menu_select", -6.0)
				last_choice = String(page.choices[choice][0])
				var branch: Array = page.choices[choice][1]
				_pages.remove_at(0)
				_pages = branch + _pages
				if _pages.is_empty():
					_close()
				else:
					phase = Phase.TYPING
					_load_page()
		Phase.CLOSING:
			if timer >= 3.0:
				_closed()
				finished.emit()


func _advance() -> void:
	_pages.remove_at(0)
	if _pages.is_empty():
		_close()
		return
	Sfx.play("msg_next", -8.0)
	phase = Phase.TYPING
	_load_page()


func _close() -> void:
	phase = Phase.CLOSING
	timer = 0.0
	Sfx.play("msg_close", -8.0)


## Seconds an auto box stays up once it has typed out.
func auto_hold() -> float:
	if page.has("hold"):
		return float(page.hold)
	return AUTO_HOLD + _total * AUTO_PER_CHAR


func _closed() -> void:
	phase = Phase.CLOSED
	page = {}
	speaker = null
	auto = false
	process_mode = Node.PROCESS_MODE_PAUSABLE


## Ends any conversation at once (area change, restart).
func cancel() -> void:
	if phase != Phase.CLOSED:
		_closed()
		finished.emit()
