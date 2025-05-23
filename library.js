/** 
 * Library for common functions used for GD Touhou project
 * tbh idk why im even writing documentation 
 * like anyone is gonna read it  
 * ig its too late tho now i have to continue  
*/


require('@g-js-api/g.js');

/**Music Player speed, in studs per second */
const plrSpeed = 311.58;
/**Player group */
const plr = 2;

var editor_layer = 4;
/** Group array for function-calling */
var currentGroups = [];
/** Global trigger storage, is a list of lists of trigger objects*/
var triggerObjs = {};
/** Index for trigger clusters, so **triggerObjs[spellName]** is a list of triggers for the spell */
var spellName;

/**
 * Creates an integer cycler function for groups
 * @param {number} lowerRange - The lower bound of the integer range (inclusive)
 * @param {number} upperRange - The upper bound of the integer range (inclusive)
 * @returns {function(): number} - Returns a function that returns array of group numbersintegers
 */
function createGroupCycler(lowerRange, upperRange) {
    let arr = [];
	for (let i = lowerRange; i <= upperRange; i++) { // 1-10
        arr.push(i);
    }
    let currentIndex = 0; // Tracks the current position in the array
    return function nextGroup() {
        const next = arr[currentIndex];
        currentIndex = (currentIndex + 1) % arr.length;
        if (currentIndex === 0) {
            currentIndex = 0; // Loop back to start
        }
        return next;
    };
}

/**
 * @param {Array<import('group').group>} groups - List of 'group()'s
 * @param {string} spell_name - For referencing later to grab
 */
function ConfigureSpell(groups, editorLayer, spell_name) {
    if (!Array.isArray(triggerObjs[spell_name])) {
        triggerObjs[spell_name] = []; // reason: if spell_name already exists, dont overrwrite the list.
    }
    spellName = spell_name;
    currentGroups = groups;
    editor_layer = editorLayer;
}

/** Call at the end of the file. Adds all objects in the triggerObs list */
function SaveToLevel(){
	// randomize positions: over time for each spell, they should spread out more statistically
	for (let spell in triggerObjs){
		let xOffset = RandomInt(0,100)*30 + 1125; // same for each spell to preserve SpawnOrder
		for (let obj of triggerObjs[spell]){
			obj.X = obj.X + xOffset;
			obj.Y = 4085 + RandomInt(0,100)*30;
			$.add(object(obj));
		}
	}
}


/** Generates a random integer from a range, inclusive of min and max */
function RandomInt(min, max) {
	return Math.floor(Math.random() * (max - min + 1) + min);
}
/** Convert seconds into plrSpeed displacement. */
function timeToDistance(seconds){
    return seconds * plrSpeed;
}
/** Convert block studs & projectile speed to trigger spacing. 
 * For moving targets shot in succession to have precise gaps.
 * @returns {number} displacement in studs. (1/30 of block)*/
function spacingProjectile(speedOfProjectile, studsOfSpacing){
    return studsOfSpacing / speedOfProjectile * plrSpeed;
}

/** Set the current group context. @param {Array<import('group').group>} arr*/
function setCurrentGroups(arr){
    currentGroups = arr;
}

/**
 * Toggles a group on or off
 * @param {boolean} activateGroup - Activate or Deactivate group
*/
function Toggle(xpos, target, activateGroup){
	triggerObjs[spellName].push({
		OBJ_ID: 1049,
		X: xpos, Y: 0,
		HOLD: target,
		TARGET: group(target),
		GROUPS: [...currentGroups],
		SPAWN_TRIGGERED: true,
		MULTI_TRIGGER: true,
		EDITOR_LAYER_1: editor_layer,
		56: activateGroup, // activate group property
	});
}

/** Spawn activates a group
 * @param {string} remapID - ID string for remapping trigger group, example: 3.5.2.10 -> remaps 3 to 5, 2 to 10
*/
function Spawn(xpos, target, remapID, spawnOrdered){
	triggerObjs[spellName].push({
		OBJ_ID: 1268, // spawn trigger id
		X: xpos, Y: 0,
		TARGET: group(target),
		GROUPS: [...currentGroups],
		REMAPS: remapID, // 3.5.2.10 -> remaps 3 to 5, 2 to 10
		581: true, // reset remaps
		441: spawnOrdered,
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
		EDITOR_LAYER_1: editor_layer
	});
}

/**
 * Shifts a color of a group by HSB. Overrides previous pulses to the group
 * 
 * UNFINISHED: Saturation & Brightness check boxes haven't been figured out yet
 * @param {number} h - Hue [-180 to +180]
 * @param {number} s - Saturation [x0.0 to x2.0], 1.0 is default
 * @param {number} b - Brightness [x0.0 to x2.0], 1.0 is default
 */
function ColorShift(xpos, target, h,s,b){
	triggerObjs[spellName].push({
		OBJ_ID: 1006, // pulse trigger id
		X: xpos, Y: 0,
		TARGET: group(target),
		TARGET_TYPE: true, // bool, false = color channel, true = group ID
		GROUPS: [...currentGroups],
		49: `${h}a${s}a${b}a${0}a${0}`, // works???
		HOLD: 10000, // should be seconds of duration, untested
		PULSE_HSV: true,
		86: true, // exclusive
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
		EDITOR_LAYER_1: editor_layer,
	});
}

/**
 * Scales a group by some factor, resets after some duration
 * @param {number} xpos - Set it to beginning of spell
 * @param {number} target - Target group to scale
 * @param {number} scaleFactor - Scale factor float, multiplied (e.g. 0.5 is half size)
 * @param {number} duration - Seconds before resetting to default size
 */
function Scale(xpos, target, scaleFactor, duration){
	triggerObjs[spellName].push({
		OBJ_ID: 2067, // scale trigger id
		X: xpos, Y: 0,
		150: scaleFactor, // scale x
		151: scaleFactor, // scale y
		51: target, // target group
		71: target, // center group
		DURATION: 0, // goes to scale instantly
		GROUPS: [...currentGroups],
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
		EDITOR_LAYER_1: editor_layer,
	},{
		OBJ_ID: 2067,
		X: xpos + timeToDistance(duration), Y: 0,
		150: scaleFactor, // scale x
		151: scaleFactor, // scale y
        DIV_BY_X: true, DIV_BY_Y: true,
		51: target, // target group
		71: target, // center group
		GROUPS: [...currentGroups],
		DURATION: 0, // instant reset
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
		EDITOR_LAYER_1: editor_layer,
	});
}

/**
 * Moves a group in the direction of another group
 * @param {number} target - Target group to move
 * @param {number} targetDir - Target direction group
 * @param {number} distance - Keep at least 400 to ensure the bullet leaves the screen (or despawn it)
 * @param {number} easing - Ease option type, 0=none
 * @param {number} easeRate - Easing rate/exponent, float or int
 */
function MoveTowardsGroup(xpos, target, targetDir, distance, time, easing, easeRate){
	triggerObjs[spellName].push({
		OBJ_ID: 901, // move trigger id
		X: xpos, Y: 0,
		TARGET_DIR_CENTER: group(target),
		TARGET_POS: group(targetDir),
		TARGET: group(target),
		DURATION: time,
		EASING: easing, EASING_RATE: easeRate,
		394: true, // directionMode
		396: distance, // distance, 30 studs =  1 block
		EDITOR_LAYER_1: editor_layer,
		GROUPS: [...currentGroups],
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
    });
}

/**
 * Moves a group by a change in X and Y
 * @param {number} target - Target group to move
 * @param {number} xchange - In studs
 * @param {number} ychange - In studs
 * @param {number} easing - Ease option type, 0=none
 * @param {number} easeRate - Easing rate, float or int
 */
function MoveBy(xpos, target, xchange, ychange, duration, easing, easeRate){
	triggerObjs[spellName].push({
		OBJ_ID: 901, // move trigger id
		X: xpos, Y: 0,
		TARGET: group(target),
		DURATION: duration, // speed in studs/seconds
		EASING: easing, EASING_RATE: easeRate,
		MOVE_X: xchange, MOVE_Y: ychange,
		EDITOR_LAYER_1: editor_layer,
		GROUPS: [...currentGroups],
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
    });
}

/**
 * Moves a group to a group in a certain amount of time
 * @param {number} target - Target group to move
 * @param {number} location - Target location group
 * @param {number} easing - Ease option type, 0=none
 * @param {number} easeRate - Easing rate, float or int
 */
function GotoGroup(xpos, target, location, time, easing, easeRate){
	triggerObjs[spellName].push({
		OBJ_ID: 901, // move trigger id
		X: xpos, Y: 0,
		TARGET_DIR_CENTER: group(target),
		TARGET_POS: group(location),
		TARGET: group(target),
		DURATION: time,
		EASING: easing, EASING_RATE: easeRate,
		100: true, // target mode
		EDITOR_LAYER_1: editor_layer,
		GROUPS: [...currentGroups],
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
	});
}

/**
 * Rotate a group to permanently point towards another group
 * @param {number} target - Target group to rotate
 * @param {number} targetDir - Target direction group
 */
function PointToGroup(xpos, target, targetDir, time, easing, easeRate) {
	triggerObjs[spellName].push({
		OBJ_ID: 1346, // rotate trigger id
		X: xpos, Y:0,
		401: targetDir, // plr = group(2)
		TARGET_POS: group(target),
		TARGET: group(target),
		DURATION: time,
		EASING: easing, EASING_RATE: easeRate,
		EDITOR_LAYER_1: editor_layer,
		GROUPS: [...currentGroups],
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
		100: true // aim mode boolean
	});
}

/**
 * Rotates a group by an angle
 * @param {number} target - Target group to rotate
 * @param {number} center - Group, center of rotation
 * @param {number} angle - In degrees, clockwise is +
 */
function Rotate(xpos, target, center, angle, time, easing, easeRate){
	triggerObjs[spellName].push({
		OBJ_ID: 1346, // rotate trigger id
		X: xpos, Y: 0,
		CENTER: group(center), // center group	
		TARGET: group(target),
		DURATION: time,
		EASING: easing, EASING_RATE: easeRate,
		EDITOR_LAYER_1: editor_layer,
		GROUPS: [...currentGroups],
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
		68: angle // degrees
	});
}

/**
 * Changes radius of a circle by scale. By default every circle will be 
 * @param {number} targetCircle - Target circle to scale
 * @param {number} radius - in base units, i.e. 1/30 of a block
 * @param {boolean} divByValue - Whether the scale is multiplied or divided (for resetting size accurately)
 */
function changeRadius(xpos, targetCircle, radius, divByValue, time, easing, easeRate){
	let scaleFactor = radius / radius;
	triggerObjs[spellName].push({
		OBJ_ID: 2067, // scale trigger id
		X: xpos, Y: 0,
        DIV_BY_X: divByValue, DIV_BY_Y: divByValue,
		150: scaleFactor, // scale x
		151: scaleFactor, // scale y
		51: targetCircle, // target group
		71: targetCircle, // center group
		DURATION: time, // goes to scale instantly
		GROUPS: [...currentGroups],
		EASING: easing, EASING_RATE: easeRate,
		SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
		EDITOR_LAYER_1: editor_layer,
	});
}

/**
 * 
 * @param {string} spell_name
 * @param {function(): number} nextBullet - IMPORTANT: define cycler function globally; dont redefine
 * @param {function({}): boolean} obj_condition - custom filter function for which objects to remap
 * @returns {string} - string remap for spawn triggers
 */
function remapSpell(spell_name, nextBullet, obj_condition){
	const spellObjects = triggerObjs[spell_name];
	if (!Array.isArray(spellObjects)){
		console.warn(`REMAP_SPELL ERROR: Spell name ${spell_name} doesnt exist`);
	}

	const remapParts = [];

    for (const obj of spellObjects) {
		if (obj_condition(obj.TARGET)){
        	remapParts.push(`${obj.TARGET["value"]}.${nextBullet()}`);
		}
    }

    return remapParts.join('.') + '.';
}

class ObjectIDs {
	constructor(){
		this.scale_trigger = 2067;
		this.move_trigger = 901;
		this.rotate_trigger = 1346;
		this.toggle_trigger = 1049;
		this.spawn_trigger = 1268;
	}
}


module.exports = {
    plr,
    plrSpeed,
    editor_layer,
    currentGroups,
    triggerObjs,
    createGroupCycler,
    RandomInt,
    ConfigureSpell,
    timeToDistance,
    spacingProjectile,
    setCurrentGroups,
    Toggle,
    Spawn,
    ColorShift,
    Scale,
    MoveTowardsGroup,
    MoveBy,
    GotoGroup,
    PointToGroup,
    Rotate,
	SaveToLevel,
	changeRadius,
	remapSpell,
	ObjectIDs
}