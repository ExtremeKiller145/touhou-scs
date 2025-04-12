const { v4: uuidv4 } = require("uuid");
const { Toggle, GotoGroup, createGroupCycler, ConfigureNewSpell, ColorShift, Scale, MoveBy, Rotate, MoveTowardsGroup, setCurrentGroups, Spawn } = require("./library")

nextPointer = createGroupCycler(601,1100);
nextBullet2 = createGroupCycler(1101,1600); // arrow
nextBullet3 = createGroupCycler(1601,2100); // circle w/ ring

function radial(numOfBullets, speed, centerGroup, nextBullet, pointInDirection){
    
}

function Fairy1(fairyGroup, spellGroup, optimizerGroup, speed){
    ConfigureNewSpell([group(optimizerGroup)],4,'sigma');
    
    GotoGroup(0,10,fairyGroup,0,0,0);
    ColorShift(1,10,40,0,0);
    Scale(2,10,0.5,8);
    Toggle(3,10,true);

    setCurrentGroups([group(spellGroup)]); // changes the global currentGroups
    let i = 0;
    let jew = 0;
    // Removed the outside for loop to reduce object count for easier testing
    // for (let i = 0; i < 5; i++){
        for (let j = 0; j < 6; j++){
            let bullet = nextBullet3();
            let angle = jew * 2 * Math.PI / 10;
            let x = 10 * 30 * Math.cos(angle) - i * 5;
            let y = 10 * 30 * Math.sin(angle) - i * 5;
            Spawn(jew*30, optimizerGroup, `10.${bullet}`, true);
            
            MoveBy(3 + jew*30,bullet,x,y,300 / speed,0,0);
        }
    // }
}

function DaiyouseiNonSpell1(){
    
}


module.exports = {
    Fairy1,
    DaiyouseiNonSpell1
}