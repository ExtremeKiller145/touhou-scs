const { v4: uuidv4 } = require("uuid");
const { Toggle, GotoGroup, createGroupCycler, ConfigureNewSpell, ColorShift, Scale, MoveBy, Rotate, MoveTowardsGroup, setCurrentGroups, Spawn, PointToGroup, timeToDistance } = require("./library")

let nextPointer = createGroupCycler(601,1100);
let nextBullet2 = createGroupCycler(1101,1600); // arrow
let nextBullet3 = createGroupCycler(1601,2100); // circle w/ ring

/** increases clockwise in increments of 3 degrees, center is 2221 & ALL is 2222 */
let pointerCircleGroups = [];
for (let i = 2101; i <= 2220; i++){
    pointerCircleGroups.push(i);
}

function radial(numOfBullets, speed, centerGroup, nextBullet, pointInDirection){
    
}

function Fairy(fairyGroup, spellGroup, optimizerGroup, optimizerGroup2, speed, spellName){
    ConfigureNewSpell([group(optimizerGroup)],4,spellName);
    let placeholder = nextPointer();
    GotoGroup(0,10,fairyGroup,0,0,0);
    ColorShift(1,10,40,1,1);
    Scale(2,10,0.5,8);
    Toggle(3,10,true);
    PointToGroup(4,10,placeholder,0,0,0);
    MoveTowardsGroup(4,10,placeholder,400,400/speed,3,1.3);

    setCurrentGroups([group(spellGroup)]);
    GotoGroup(0,2222,fairyGroup,0,0,0);
    Rotate(5,2222,2222,50,2,2,2);
    for (let j = 0; j < 10; j++){
        for (let i = 0; i < 24*5; i = i + 5){
            let ptr = pointerCircleGroups[i];
            let bullet = nextBullet2();
            let x = Math.floor(j*timeToDistance(0.1));
            Spawn(x, optimizerGroup, `10.${bullet}.${placeholder}.${ptr}`, true);
        }
    }
}

function Fairy1(fairyGroup, spellGroup, optimizerGroup, speed, spellName){
    ConfigureNewSpell([group(optimizerGroup)],4,spellName);
    
    GotoGroup(0,10,fairyGroup,0,0,0);
    ColorShift(1,10,40,1,1);
    Scale(2,10,0.5,8);
    Toggle(3,10,true);

    setCurrentGroups([group(spellGroup)]); // changes the global currentGroups


    for (let i = 1; i <= 50; i++){
        for (let j = 0; j < 10; j++){
            let bullet = nextBullet3();
            let angle = j * 2 * Math.PI / 10;
            let x = 10 * 30 * Math.cos(angle);
            let y = 10 * 30 * Math.sin(angle);
            Spawn(j*2 + i*5, optimizerGroup, `10.${bullet}`, true);
            
            MoveBy(3 + j*2 + i*5,bullet,x,y, (300 / speed)/i ,0,0);
        }
    }
}

function DaiyouseiNonSpell1(){
    
}


module.exports = {
    Fairy1,
    Fairy,
    DaiyouseiNonSpell1
}