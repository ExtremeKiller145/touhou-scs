// test-generate.js - Generate sample triggers.json for testing the debugger

const fs = require('fs');
const path = require('path');

// Generate sample triggers that demonstrate various relationships
function generateSampleTriggers() {
  const triggers = [];

  // Spawn some bullets in group 5000
  triggers.push({
    ObjID: 1,
    Type: 1,
    GroupID: 5000,
    X: 100,
    Y: 200,
    ComponentName: "BulletSpawner"
  });

  triggers.push({
    ObjID: 1,
    Type: 1,
    GroupID: 5000,
    X: 150,
    Y: 200,
    ComponentName: "BulletSpawner"
  });

  // Move trigger targeting group 5000
  triggers.push({
    Type: 901,
    TargetGroupID: 5000,
    MoveX: 10,
    MoveY: 5,
    Duration: 1.0,
    Easing: 2,
    ComponentName: "MoveBullets"
  });

  // Rotate trigger targeting group 5000
  triggers.push({
    Type: 1346,
    TargetGroupID: 5000,
    RotateDegrees: 45,
    Duration: 0.5,
    CenterGroupID: 6000,
    ComponentName: "RotateBullets"
  });

  // Spawn center object for rotation
  triggers.push({
    ObjID: 211,
    Type: 1,
    GroupID: 6000,
    X: 200,
    Y: 200,
    ComponentName: "RotationCenter"
  });

  // Remap trigger that references group 5000
  triggers.push({
    Type: 3608,
    TargetGroupID: 7000,
    Remap: "10.5000.20.5001",
    ComponentName: "RemapTrigger"
  });

  // Spawn objects in group 5001
  triggers.push({
    ObjID: 1,
    Type: 1,
    GroupID: 5001,
    X: 300,
    Y: 250,
    ComponentName: "RemappedBullet"
  });

  // Pulse trigger targeting group 5001
  triggers.push({
    Type: 1006,
    TargetGroupID: 5001,
    FadeIn: 0.1,
    Hold: 0.5,
    FadeOut: 0.1,
    PulseType: 1,
    ComponentName: "PulseBullets"
  });

  // Multi-target spawn trigger (simulating binary decomposition)
  triggers.push({
    ObjID: 1,
    Type: 1,
    GroupID: 8000,
    MULTITRIGGER: "10.8001.20.8002.30.8003",
    ComponentName: "MultiTargetSpawn"
  });

  // Some triggers in the multitarget chain
  triggers.push({
    Type: 901,
    TargetGroupID: 8001,
    MoveX: 5,
    MoveY: 0,
    Duration: 1.0,
    ComponentName: "MoveSubset1"
  });

  triggers.push({
    Type: 901,
    TargetGroupID: 8002,
    MoveX: -5,
    MoveY: 0,
    Duration: 1.0,
    ComponentName: "MoveSubset2"
  });

  triggers.push({
    Type: 901,
    TargetGroupID: 8003,
    MoveX: 0,
    MoveY: 10,
    Duration: 1.0,
    ComponentName: "MoveSubset3"
  });

  // A complex chain: spawn -> move -> remap -> pulse
  triggers.push({
    ObjID: 1,
    Type: 1,
    GroupID: 9000,
    X: 400,
    Y: 300,
    ComponentName: "ChainStart"
  });

  triggers.push({
    Type: 901,
    TargetGroupID: 9000,
    MoveX: 20,
    MoveY: 20,
    Duration: 2.0,
    ComponentName: "ChainMove"
  });

  triggers.push({
    Type: 3608,
    TargetGroupID: 9100,
    Remap: "10.9000.20.9001",
    ComponentName: "ChainRemap"
  });

  triggers.push({
    Type: 1006,
    TargetGroupID: 9001,
    FadeIn: 0.2,
    Hold: 1.0,
    FadeOut: 0.2,
    PulseType: 0,
    ComponentName: "ChainPulse"
  });

  // Some unknown_g references (like the real system uses)
  triggers.push({
    Type: 3608,
    TargetGroupID: 10000,
    Remap: "10.unknown_g1.20.unknown_g2",
    ComponentName: "UnresolvedRemap"
  });

  return triggers;
}

// Write to triggers.json
const triggers = generateSampleTriggers();
const outputPath = path.join(__dirname, '..', 'triggers.json');

fs.writeFileSync(outputPath, JSON.stringify(triggers, null, 2));

console.log(`✅ Generated ${triggers.length} sample triggers`);
console.log(`📁 Written to: ${outputPath}`);
console.log('');
console.log('Now run: node debug/debug.js');
