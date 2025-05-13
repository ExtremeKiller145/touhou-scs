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

class Circular {
    // note for later: 
    // if necessary, create more circles to be used w/ multiple emitters simultaneously
    static ptrCircleCenter = 2221; // not permanent
    static ptrCircleAll = 2222; // not permanent
    static ptrCircleGroups = (() => {
        let groups = [];
        for (let i = 2101; i <= 2220; i++){
            groups.push(i); // starts at 2101 and goes clockwise
        }
        return groups;
    })();

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
    }
    
    static baseRadialGroup = unknown_g();
    static firstRun = true;
    /**
     * You may need to rerun the ConfigureSpell method again after running this function
     * @param {TriggerSet} triggerSet
     */
    static Radial(xPosition, triggerSet){
        if (this.firstRun){
            this.firstRun = false;
            let baseOptimizer = unknown_g();
            let baseEmitter = unknown_g();
            let baseTargetCircle = unknown_g();
            let baseBullet = unknown_g();
            lib.ConfigureSpell([baseOptimizer],5,'RadialOptimizer');
            lib.GotoGroup(0, baseOptimizer, baseEmitter, 0,0,0);
            lib.Toggle(1,baseBullet,true);
            lib.PointToGroup(0, baseBullet, baseTargetCircle, 0,0,0);
            triggerSet.moveTriggers.forEach((moveTrig) => {
                lib.MoveTowardsGroup(2, baseBullet, baseTargetCircle, 
                    moveTrig.Distance, moveTrig.Time,moveTrig.Easing, moveTrig.EaseRate, moveTrig.Dynamic, moveTrig.X);
            });
            lib.ConfigureSpell([this.baseRadialGroup], 5, 'BaseRadial');
            for (i = 1; i <= 121; i++){
                // IMPORTANT: If using multiple circles, 
                lib.Spawn(0, group(i), `${baseBullet}.${i}.${baseTargetCircle}.${2100+i}`,0,0,0);
            }
        } else {
            // compare with allTriggerSets. If it is a repeat for unique trigger settings,
            // then dont add, just apply to new bullets
            const duplicateSet = this.#processTriggerSet(triggerSet);
            if (duplicateSet != undefined){
                let activateGroup = duplicateSet.activatorGroup;
                // run a spawn trigger with a full remap string to remap
                console.log(`Duplicate trigger set found. Remapping bullets for group ${activateGroup}`);
            }
        }
    }

    static CompileRadials(){
        // reconfigure BaseRadial with the extra triggers & assign the toggleOn/toggleOff groups
        lib.ConfigureSpell([this.baseRadialGroup], 5, 'BaseRadial');
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