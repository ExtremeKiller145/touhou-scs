const lib = require('./library');
const spell = require('./spells');

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
    // call builder function stuff here
    // Fairy1(37,36,20,20,`call1`);
	
	spell.FairyTest(37,36,20,21,120,`call1`);
	lib.ConfigureSpell([group(36)],4,'main');
	// lib.Spawn(0,36,lib.remapSpell('call1',spell.nextBullet2),true);
    lib.SaveToLevel();
});
