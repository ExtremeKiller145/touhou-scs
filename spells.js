const { v4: uuidv4 } = require("uuid");
const lib = require("./library")
require('./library');
let nextPointer = lib.createGroupCycler(601,1100);
let nextBullet2 = lib.createGroupCycler(1101,1600); // arrow
let nextBullet3 = lib.createGroupCycler(1601,2100); // circle w/ ring

/** increases clockwise in increments of 3 degrees, center is 2221 & ALL is 2222 */
let ptrCircleGroups = [];
for (let i = 2101; i <= 2220; i++){
    ptrCircleGroups.push(i);
}

function radial(numOfBullets, speed, centerGroup, nextBullet, pointInDirection){
    
}

function FairyTest(fairyGroup, spellGroup, optimizerGroup, optimizerGroup2, speed, spellName){
    lib.ConfigureSpell([group(optimizerGroup)],4,spellName);
    let placeholder = nextPointer();
    lib.GotoGroup(0,10,fairyGroup,0,0,0);
    lib.ColorShift(1,10,-116,0.46,1);
    lib.Scale(2,10,0.5,400/speed);
    lib.Toggle(3,10,true);
    lib.PointToGroup(4,10,placeholder,0,0,0);
    lib.MoveTowardsGroup(4,10,placeholder,400,400/speed,3,1.3);

    lib.setCurrentGroups([group(spellGroup)]);
    lib.GotoGroup(0,2222,fairyGroup,0,0,0);
    lib.Rotate(5,2222,2222,50,2,2,2);
    for (let j = 0; j < 5; j++){
        for (let i = 0; i < 24*5; i = i + 5){
            let ptr = ptrCircleGroups.at(i); // use .at(i) instead of [i] for negative index support
            let x = Math.floor(j*lib.timeToDistance(0.2));
            lib.Spawn(x, optimizerGroup, `10.${nextBullet2()}.${placeholder}.${ptr}`, true);
        }
    }
}

function Fairy1(fairyGroup, spellGroup, optimizerGroup, speed, spellName){
    lib.ConfigureNewSpell([group(optimizerGroup)],4,spellName);
    
    lib.GotoGroup(0,10,fairyGroup,0,0,0);
    lib.ColorShift(1,10,40,1,1);
    lib.Scale(2,10,0.5,8);
    lib.Toggle(3,10,true);

    lib.setCurrentGroups([group(spellGroup)]); // changes the global currentGroups


    for (let i = 1; i <= 50; i++){
        for (let j = 0; j < 10; j++){
            let bullet = nextBullet3();
            let angle = j * 2 * Math.PI / 10;
            let x = 10 * 30 * Math.cos(angle);
            let y = 10 * 30 * Math.sin(angle);
            lib.Spawn(j*2 + i*5, optimizerGroup, `10.${bullet}`, true);
            
            lib.MoveBy(3 + j*2 + i*5,bullet,x,y, (300 / speed)/i ,0,0);
        }
    }
}

function DaiyouseiNonSpell1(){
    
}


module.exports = {
    Fairy1,
    FairyTest,
    DaiyouseiNonSpell1,
    nextBullet2,
    nextBullet3,
    nextPointer
}