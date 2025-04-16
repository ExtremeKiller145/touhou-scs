const { SaveToLevel } = require('./library');
const { Fairy1, Fairy } = require('./spells');

require('@g-js-api/g.js');

$.exportConfig({
	type: 'live_editor', 
	// type can be 'savefile' to export to savefile, 'levelstring' to return levelstring 
	// or 'live_editor' to export to WSLiveEditor (must have Geode installed)geome
	options: {
		info: true,
		level_name: "test",
	}
}).then(a => {
    // call trigger builder function stuff here
    // Fairy1(37,36,20,20,`call1`);
	Fairy(37,36,20,21,120,`call1`);
    SaveToLevel();
});
