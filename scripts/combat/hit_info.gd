class_name HitInfo
extends RefCounted
## Data describing a single attack hitting a Hurtbox.

var damage := 1
var knockback := 4.0
var attacker: Node3D
## World position the attack came from (used for knockback and shield direction).
var source_position := Vector3.ZERO
## Too heavy for the shield (the Tide Knight's chop): it hits a guarding hero anyway.
var unblockable := false
## Something heavy thrown by the hero (a pot or a rock): it breaks brittle things.
var heavy := false
## A bomb's blast (creatures armored against blades may still feel it).
var bomb := false
## A projectile the hero turned back off his shield.
var reflected := false
## The Knight's Techniques (Chapter V): "spin" (the Great Spin), "thrust" (the
## Down Thrust's landing shock), "bash" (the Shield Bash), "ember" (the Ember
## Rod's fireball). Creatures read it to react (an undead knight's guard breaks
## to a bash); "" for every other blow.
var kind := ""
## A two-handed sword's blow (the Questlord's Greatsword): heavy enough to
## smash an undead knight's shield aside, the way a Shield Bash does.
var cleave := false
