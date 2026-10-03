class_name MapData
extends RefCounted
## The overworld of Lumen Hollow, authored as ASCII so it is easy to tweak.
##
## Legend
##   ^  high cliff        #  low cliff        w  invisible wall (grass)
##   .  grass             ,  tall grass (random encounters)
##   =  dirt path         s  stone plaza      b  wooden bridge     ~  river
##   T  broadleaf tree    P  pine tree        o  bush              r  boulder
##   f  flowers           F  fence            L  street lamp       W  well (2x2)
##   h  house footprint (rectangles become houses)
##   d  door (placed on the south wall of the house above it)
##   @  player start      K  boss             C  treasure chest

const ROWS := [
	"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
	"^^^^^^^^^^^^^^PP..........PP^^^^^^^^^^^^",
	"^^^^^^^^^^^^P...ssssssss...P^^^^^^^^^^^^",
	"^^^^^^^^^^^P..ss........ss..P^^^^^^^^^^^",
	"^^PP^^^^^^^P.ss.....K....ss.P^^^^^^PP^^^",
	"^^P.P^^^^^^P..ss...C....ss..P^^^^^P..P^^",
	"^^P..##^^^^PP..ssss==ssss..PP^^^##...P^^",
	"^^P...####^^PP.....==.....PP^####..r..^^",
	"^^PP....,,###TT....==....TT###,,,.....P^",
	"^^P....,,,,,,.....,==,.....,,,,,,,....P^",
	"^^P...,,,,,,,,T..,,==,,..T,,,,,,,,,..CP^",
	"^^T..,,,,r,,,,,..,,==,,..,,,,,r,,,,,..T^",
	"^^T..,,,,,,,,,f..,,==,,.f.,,,,,,,,,,..T^",
	"^^T...,,,,,,,T....===.....T,,,,,,,,..fT^",
	"^^TT.f..,,,,,......==.....,,,,,,....TTT^",
	"^^^TT.......o.....f==f......o.......TT^^",
	"^^^^~~~~~~~~~~~~~~~bb~~~~~~~~~~~~~~~~^^^",
	"^^^~~~~~~~~~~~~~~~~bb~~~~~~~~~~~~~~~~~^^",
	"^^^TT.....f.......f==f.......f....TT.^^^",
	"^^TT..FFFFFF......L==L......FFFFFF..TT^^",
	"^^T.................==................T^",
	"^^T..hhhhhh.........==.........hhhhhh.T^",
	"^^T..hhhhhh....ssssssssss......hhhhhh.T^",
	"^^T..hhhhhh....ssssssssss......hhhhhh.T^",
	"^^T..hhhhhh..L.ssssssssss.L....hhhhhh.T^",
	"^^T..f.d.f.....ssssWWssss......f..d.f.T^",
	"^^T....==========ssWWss==========.==..T^",
	"^^T....f.......ssssssssss.......f.....T^",
	"^^T.....o......ssssssssss.......o.....T^",
	"^^T..hhhhh.....ssssssssss....hhhhhh...T^",
	"^^T..hhhhh.....L...==...L....hhhhhh...T^",
	"^^T..hhhhh.........==........hhhhhh...T^",
	"^^T..hhhhh.........==........hhhhhh..CT^",
	"^^T..f.d.f....f....@=....f.....d.f....T^",
	"^^TT...===========.==...========.....TT^",
	"^^TTT...............==..............TTT^",
	"^^wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww^^",
	"^^wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww^^",
]

## Signs, NPCs and chests reference grid cells (x = column, y = row).
const NPCS := [
	{"id": "elder", "sprite": "elder", "name": "Elder Maren", "cell": Vector2i(17, 27), "facing": 0,
		"wander": false},
	{"id": "innkeeper", "sprite": "innkeeper", "name": "Innkeeper Rosa", "cell": Vector2i(9, 26),
		"facing": 0, "wander": false},
	{"id": "merchant", "sprite": "merchant", "name": "Merchant Tobin", "cell": Vector2i(32, 26),
		"facing": 0, "wander": false},
	{"id": "child", "sprite": "child", "name": "Pip", "cell": Vector2i(22, 29), "facing": 0,
		"wander": true},
	{"id": "guard", "sprite": "guard", "name": "Guard Halvard", "cell": Vector2i(22, 18), "facing": 0,
		"wander": false},
	{"id": "fisher", "sprite": "fisher", "name": "Old Wick", "cell": Vector2i(11, 18), "facing": 3,
		"wander": false},
]

const SIGNS := [
	{"cell": Vector2i(23, 20), "text": ["North: Whispering Meadow & the Old Shrine.", "South: Lumen Hollow."]},
	{"cell": Vector2i(12, 25), "text": ["The Sleeping Fox Inn.", "Rest your weary bones!"]},
	{"cell": Vector2i(37, 25), "text": ["Tobin's Sundries.", "Grapes, plums and other curatives."]},
]

const CHESTS := {
	Vector2i(19, 5): {"item": "feather", "count": 1},
	Vector2i(37, 10): {"item": "ether", "count": 2},
	Vector2i(37, 32): {"item": "potion", "count": 2},
}

const SOLID := "^#wTPorFLWh~"


static func width() -> int:
	return ROWS[0].length()


static func depth() -> int:
	return ROWS.size()


static func cell(x: int, y: int) -> String:
	if y < 0 or y >= ROWS.size() or x < 0 or x >= ROWS[0].length():
		return "^"
	return ROWS[y][x]


static func height_of(c: String) -> float:
	match c:
		"^": return 3.0
		"#": return 2.0
		"~": return -0.3
	return 0.0


static func find(ch: String) -> Vector2i:
	for y in ROWS.size():
		var x: int = ROWS[y].find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


## World-space centre of a grid cell (ground level).
static func cell_center(c: Vector2i) -> Vector3:
	return Vector3(c.x + 0.5, 0.0, c.y + 0.5)


static func world_to_cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.z))
