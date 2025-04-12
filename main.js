const { SaveToLevel, MoveTowardsGroup, ConfigureNewSpell, ColorShift, Scale, Toggle, Spawn, GotoGroup, triggerObjs } = require('./library');
const { Fairy1 } = require('./spells');

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
    Fairy1(37,36,20,100);

    // ConfigureNewSpell([group(20)],4,'sigma');
    // for (let i = 0; i < 2; i++){
    //     GotoGroup(0+i,10,37,0,0,0);
    //     ColorShift(1+i,10,40,0,0);
    //     Scale(2+i,10,0.5,8);
    //     Toggle(3+i,10,true);
    // }
    // ConfigureNewSpell([group(36)],4,'testingger');
    // for (let i = 0; i < 50; i++){
    // MoveTowardsGroup(i*10,2,37,50,0.5,0,0);}
    SaveToLevel();
});
