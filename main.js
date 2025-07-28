require('@g-js-api/g.js');

$.exportConfig({
	type: 'live_editor', 
	// type can be 'savefile' to export to savefile, 'levelstring' to return levelstring 
	// or 'live_editor' to export to WSLiveEditor (must have Geode installed)
	options: {
		info: true,
		level_name: "ttests",
	}
}).then(a => {
	const jsonData = require('fs').readFileSync('triggers.json', 'utf8');
	const data = JSON.parse(jsonData);
	const triggers = data.triggers.map(trigger => {
		return Object.keys(trigger).reduce((acc, key) => {
			if (key === '57' && Array.isArray(trigger[key])) {
				// Transform '57' array and create GROUPS property for G.js compatibility
				// didnt translate automatically for unknown reasons
				acc['GROUPS'] = trigger[key].map(groupValue => {
					if (typeof groupValue === 'number') {
						return group(groupValue);
					} else if (groupValue === 'unknown_g') {
						return unknown_g(); // No args - returns new unused group
					}
					return groupValue; // fallback
				});
				// Don't copy the original '57' key
			} else {
				acc[key] = trigger[key];
			}
			return acc;
		}, {});
	});
	triggers.forEach(trigger => {
		// console.log('trigger test:');
		// console.log(trigger);
		// console.log('trigger test wrapped in "object()":');
		// console.log(object(trigger));
		$.add(object(trigger));
	});
	// console.log('object example:');
	// const obj = {
	// 	OBJ_ID: 901, // move trigger id
	// 	X: 15, Y: 45,
	// 	TARGET_DIR_CENTER: group(4),
	// 	TARGET_POS: group(5),
	// 	TARGET: group(6),
	// 	DURATION: 2.3,
	// 	EASING: 2, EASING_RATE: 1.4,
	// 	394: true, // directionMode
	// 	396: 142, // distance, 30 studs =  1 block
	// 	EDITOR_LAYER_1: 4,
	// 	GROUPS: [group(2),group(1), unknown_g()],
	// 	SPAWN_TRIGGERED: true, MULTI_TRIGGER: true,
	// }
	// console.log(obj);
	// console.log('object example wrapped in "object()":');
	// console.log(object(obj));
	// $.add(object(obj));
});
