const { unknown_g } = require('index');
const lib = require('./library');
require('@g-js-api/g.js');

class TriggerSet {
    /**
     * @param {function(): number} nextBullet
     * @param {number} activateGroup - group that calls the unique toggle-on, toggle-off & spawn trigger.
     * @param {number} [dynamicRotateDuration=0]
     */
    constructor(nextBullet, emitter, activateGroup, scale = 1, scaleDuration, dynamicRotateDuration = 0, intervalAngle = 3) {
        this.emitter = group(emitter);
        this.scaleTrigger = { scale: scale, duration: scaleDuration, groups: [] };
        this.dynamicRotateDuration = { duration: dynamicRotateDuration, groups: [] };
        this.activatorGroup = group(activateGroup);
        this.intervalAngle = intervalAngle;
        this.toggleOffGroup = unknown_g();
        this.toggleOnGroup = unknown_g();
        this.nextBullet = nextBullet;
        this._moveTriggers = [];
        this._colorTriggers = [];
        if (intervalAngle % 3 !== 0) {
            throw new TypeError(`TriggerSet interval angle must be a multiple of 3 degrees. Received: ${intervalAngle}`);
        }
    }
    /**
     * @param {Array<{Distance: number, Time: number, Easing: number, EaseRate: number, X: number}>} objectList
     */
    set moveTriggers(objectList) {
        objectList.forEach((obj, index) => {
            if (!obj.Distance || !obj.Time || !obj.Easing || !obj.EaseRate || !obj.Dynamic ||!obj.X) {
                throw new TypeError(`Move trigger at index ${index} is incorrectly assigned: ${JSON.stringify(obj)}`);
            }
        });
        this._colorTriggers = objectList;
    }
    /**
     * @param {Array<{H: number, S: number, V: number, X: number}>} objectList
     */
    set colorTriggers(objectList) {
        objectList.forEach((obj, index) => {
            if (!obj.H || !obj.S || !obj.V || !obj.X) {
                throw new TypeError(`Color trigger at index ${index} is incorrectly assigned: ${JSON.stringify(obj)}`);
            }
        });
        this._colorTriggers = objectList;
    }
    get colorTriggers() {
        return this._colorTriggers;
    }
    get moveTriggers() {
        return this._moveTriggers;
    }
}

class GuiderCircle {
    constructor(center, all, pointer, groups) {
        this.center = center;
        this.all = all;
        this.pointer = pointer;
        this.groups = groups;
    }

    static c1 = new GuiderCircle(
        2221, // Center group
        2222, // All group
        2101, // Pointer group
        (() => {
            let groups = [];
            for (let i = 2101; i <= 2220; i++) {
                groups.push(i); // Starts at 2101 and goes clockwise
            }
            return groups;
        })()
    );
}

class Circular {
    // note for later:
    // if necessary, create more circles to be used w/ multiple emitters simultaneously

    static allTriggerSets = [];
    static allMoveTriggers = [];
    static allColorTriggers = [];
    static allScales = [];
    static allDynamicRotateDurations = [];
    /**
     * Checks trigger set for duplicates & manages them. 
     * Non-duplicates are autoconfigured & added to the compilation list.
     * @param {TriggerSet} triggerSet
     * @returns {TriggerSet} - true if triggerSet is a duplicate, false if it is new
     */
    static #processTriggerSet(triggerSet){
        this.allTriggerSets.forEach((set) => {
            if (JSON.stringify(triggerSet.moveTriggers) == JSON.stringify(set.moveTriggers) &&
                JSON.stringify(triggerSet.colorTriggers) == JSON.stringify(set.colorTriggers) &&
                triggerSet.scale == set.scale &&
                triggerSet.dynamicRotateDuration == set.dynamicRotateDuration){
                return set; // duplicate found, returning to call as remaps
            }
        });
        // if no duplicates found, add to allTriggerSets
        this.allTriggerSets.push(triggerSet);
        this.allMoveTriggers.forEach((storedMoveTrig) => {
            triggerSet.moveTriggers.forEach((moveTrig) => {
                // if in  list, toggle on, if not, add trig to list w/ toggle on
                if (JSON.stringify(moveTrig) == JSON.stringify(storedMoveTrig)){
                    storedMoveTrig.groups.push(triggerSet.toggleOnGroup);
                } else {
                    moveTrig.groups = [];
                    moveTrig.groups.push(triggerSet.toggleOnGroup);
                    this.allMoveTriggers.push(moveTrig);
                }
            });
        });
        this.allColorTriggers.forEach((storedColorTrig) => {
            triggerSet.colorTriggers.forEach((colorTrig) => {
                // if in list, toggle on, if not, add trig to list w/ toggle on
                if (JSON.stringify(colorTrig) == JSON.stringify(storedColorTrig)){
                    storedColorTrig.groups.push(triggerSet.toggleOnGroup);
                } else {
                    colorTrig.groups = [];
                    colorTrig.groups.push(triggerSet.toggleOnGroup);
                    this.allColorTriggers.push(colorTrig);
                }
            });
        });
        this.allScales.forEach((storedScaleTrigger) => {
            if (triggerSet.scaleTrigger.scale == storedScaleTrigger.scale){
                storedScaleTrigger.groups.push(triggerSet.toggleOnGroup);
            } else {
                triggerSet.scaleTrigger.groups.push(triggerSet.toggleOnGroup);
                this.allScales.push(triggerSet.scaleTrigger);
            }
        });
        this.allDynamicRotateDurations.forEach((storedDynamicRotateDuration) => {
            if (triggerSet.dynamicRotateDuration.duration == storedDynamicRotateDuration.duration){
                storedDynamicRotateDuration.groups.push(triggerSet.toggleOnGroup);
            } else {
                triggerSet.allDynamicRotateDurations.groups = [];
                triggerSet.allDynamicRotateDurations.groups.push(triggerSet.toggleOnGroup);
                this.allDynamicRotateDurations.push(triggerSet.dynamicRotateDuration);
            }
        });
        return undefined; // no duplicates found
    }
    
    static baseRadialGroup = unknown_g();
    static baseBullet = unknown_g();
    static baseTargetCircle = unknown_g();
    static baseOptimizer = unknown_g();
    static baseEmitter = unknown_g();
    static baseCircleGroups = []; // logic for this does not include multiple circles
    static firstRun = true;
    /**
     * You may need to rerun the ConfigureSpell method again after running this function
     * @param {TriggerSet} triggerSet
     */
    static Radial(xPosition, triggerSet, circle = GuiderCircle.c1, spellName){
        if (circle.groups.length != 120){
            throw new TypeError(`GuiderCircle groups must be 120. Received: ${circle.groups.length}`);
        }
        if (this.firstRun){
            this.firstRun = false;
            lib.ConfigureSpell([this.baseOptimizer],5,'RadialOptimizer');
            lib.GotoGroup(0, this.baseOptimizer, this.baseEmitter, 0,0,0);
            lib.PointToGroup(1, this.baseBullet, this.baseTargetCircle, 0,0,0);
            lib.Toggle(2,this.baseBullet,true);
            // no move trigger because they will be added in
            lib.ConfigureSpell([this.baseRadialGroup], 5, 'BaseRadial');
            for (i = 0; i < 120; i++){
                lib.Spawn(0,this.baseOptimizer,`${this.baseBullet}.${i+1}.${this.baseTargetCircle}.${circle.groups[i]}`,true);
            }
            this.baseCircleGroups = circle.groups;
            console.log(`First run, Base radial created. w/ given settings.`);
        }

        // compare with allTriggerSets. If it is a repeat for unique trigger settings,
        // then dont add, just apply to new bullets
        const duplicateSet = this.#processTriggerSet(triggerSet);
        if (duplicateSet != undefined){ // if duplicate found
            let remapString = ``;
            const circleGroupsAreEqual = this.baseCircleGroups == circle.groups;
            for (let i = 0; i < 120; i++) {
                if (circleGroupsAreEqual){
                    remapString += `${i+1}.${triggerSet.nextBullet()}.${this.baseCircleGroups[i]}`
                } else {
                    remapString += `${i+1}.${triggerSet.nextBullet()}.${this.baseCircleGroups[i]}.${circle.groups[i]}.`;
                }
            }


            lib.ConfigureSpell([duplicateSet.activatorGroup],5,spellName);
            lib.Toggle(xPosition, duplicateSet.toggleOnGroup, true);
            lib.Toggle(xPosition, duplicateSet.toggleOffGroup, false);
            lib.Spawn(xPosition +1, this.baseRadialGroup, remapString, true); // ordered by xpos to run after toggles

            console.log(`Duplicate trigger set found. Remapping bullets for spell ${spellName}.`);
        }
    }

    static CompileRadials(){
        // reconfigure BaseRadial with the extra triggers & assign the toggleOn/toggleOff groups
        lib.ConfigureSpell([this.baseRadialGroup], 5, 'BaseRadial');
        this.allMoveTriggers.forEach((moveTrig) => {
            lib.MoveTowardsGroup(moveTrig.X, this.baseBullet, this.baseTargetCircle, moveTrig.Distance, moveTrig.Time, moveTrig.Easing, moveTrig.EaseRate, moveTrig.Dynamic);
        });
        this.allColorTriggers.forEach((colorTrig) => {
            lib.ColorShift(colorTrig.X, this.baseBullet, colorTrig.H, colorTrig.S, colorTrig.V);
        });
        this.allScales.forEach((scaleTrig) => {
            lib.Scale(scaleTrig.X, this.baseBullet, scaleTrig.scale, scaleTrig.duration);
        });
        this.allDynamicRotateDurations.forEach((dynamicRotate) => {
            
            lib.PointToGroup(2, this.baseBullet, this.baseTargetCircle, dynamicRotate.duration, 0,0,true);
        });
    }
}

const myTriggerSet = new TriggerSet(
    lib.createGroupCycler(1101,1600), // arrow
    37,                     // Emitter group ID
    36,                     // Activate group ID
    0.5,                    // Scale
    6,                      // Scale duration
    false,                  // Dynamic rotation
    0,                      // Dynamic rotation duration
    3                       // Interval angle
);

myTriggerSet.moveTriggers = [
    {
        Distance: 100, Time: 1.5,
        Easing: 1, EaseRate: 0.5,
        Dynamic: false, X: 0
    },
    {
        Distance: 200, Time: 3,
        Easing: 2, EaseRate: 1.0,
        Dynamic: false, X: lib.timeToDistance(1.5)
    }
];

myTriggerSet.colorTriggers = [
    { H: 180, S: 1.0, V: 1.0, X: 50 },
    { H: 90, S: 0.8, V: 0.9, X: 100 }
];

Circular.Radial(0,myTriggerSet);
Circular.CompileRadials();


module.exports = {
    TriggerSet,
    Circular
};