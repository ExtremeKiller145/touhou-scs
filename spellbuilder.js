const lib = require('./library');
require('@g-js-api/g.js');

class TriggerSet {
    /**
     * @param {function(): number} nextBullet
     */
    constructor(nextBullet, emitter, activateGroup, scale){
        this.emitter = group(emitter);
        this.scale = scale;
        this.activateGroup = activateGroup; // for calling this specific unique function
        this.toggleOffGroup = unknown_g();
        this.toggleOnGroup = unknown_g();
        this.nextBullet = nextBullet;
        this.moveTriggers = [];
        this.colorTriggers = [];
    }
    set moveTriggers(objectList){
        objectList.forEach(obj => {
            if (!obj.Distance || !obj.Time || !obj.Easing || !obj.EaseRate || !obj.X){
                const e = new TypeError("Move trigger(s) were incorrectly assigned");
                console.error(e.stack);
            }
        });
        this.moveTriggers = objectList;
    }
    set colorTriggers(objectList){
        objectList.forEach(obj => {
            if (!obj.H || !obj.S || !obj.V || !obj.X){
                const e = new TypeError("Color trigger(s) were incorrectly assigned");
                console.error(e.stack);
            }
        });
        this.colorTriggers = objectList;
    }
}

class Circular {
    static ptrCircleCenter = 2221;
    static ptrCircleGroups = (() => {
        let groups = [];
        for (let i = 2101; i <= 2220; i++){
            groups.push(i); // starts at 2101 and goes clockwise
        }
        return groups;
    })();

    /** @param {TriggerSet} triggers*/
    static Radial(triggers){

    }
}

