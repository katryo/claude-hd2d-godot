class_name InteractionFinder
extends RefCounted
## Picks what the player is trying to interact with: the closest target in reach that
## the player is roughly facing.

const REACH := 1.6
## Within this distance facing doesn't matter (the player is standing on top of it).
const FACING_MIN_DIST := 0.3
## Minimum dot product between the facing and the direction to the target.
const FACING_DOT := 0.45


## `targets` are objects with `position() -> Vector3` and `extra_reach() -> float`.
static func find(targets: Array, from: Vector3, facing: Vector3) -> Variant:
	var best: Variant = null
	var best_dist := REACH
	for t in targets:
		var d: Vector3 = t.position() - from
		d.y = 0
		var dist := d.length()
		var reach: float = best_dist + t.extra_reach()
		if dist >= reach:
			continue
		if dist > FACING_MIN_DIST and facing.dot(d.normalized()) < FACING_DOT:
			continue
		best = t
		best_dist = min(dist, best_dist)
	return best
