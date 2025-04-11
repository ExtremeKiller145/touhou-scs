require('@g-js-api/g.js');

// CHECK: g-js ./types/* for all sorts of object property constants

/** Creates collision trigger
 * @param {number} xpos - X position of trigger in studs
 * @param {number} ypos - Y position of trigger in studs
 * @param {number} target - Target group to activate
 * @param {number} blockA - Collision block A, Integer
 * @param {number} blockB - Collision block B, Integer
*/
function Collision(xpos, ypos, target, blockA, blockB){
	let col = {
		OBJ_ID: 1815, // collision trigger id
		X: xpos,
		Y: ypos,
		BLOCK_A: block(blockA),
		BLOCK_B: block(blockB),
		TARGET: group(target),
		// GROUPS: CurrentGroups,
		// SPAWN_TRIGGERED: true,
		// MULTI_TRIGGER: true,
		// EDITOR_LAYER_1: editor_layer
	}
	$.add(object(col));
}