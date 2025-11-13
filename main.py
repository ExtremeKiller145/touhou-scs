import touhou_scs.enums as e

from touhou_scs.component import Component, Multitarget
from touhou_scs.lib import rgb, save_all
from touhou_scs.utils import group, unknown_g, Remap, translate_remap_string

# Test all component trigger methods
testComp = Component("ComprehensiveTest", unknown_g())
testComp.assert_spawn_order(True)

# Basic triggers
testComp.Spawn(0.05, 501, True, remap=f"{unknown_g()}.502", delay=0.5)
testComp.Toggle(0.1, 503, True)

# Movement triggers
(testComp
    .MoveTowards(0.15, 501, e.PLR, t=2.0, dist=300, type=1, rate=2.0, dynamic=True)
    .MoveBy(0.2, 502, dx=100, dy=-50, t=1.5, type=2, rate=1.5)
    .GotoGroup(0.25, 503, e.PLR, t=1.0, type=3, rate=2.0)
)

# Rotation triggers
testComp.Rotate(0.3, target=504, angle=90, center=505, t=1.5, type=1, rate=1.0)
testComp.PointToGroup(0.35, 506, e.PLR, t=0.5, type=2, rate=1.5)

# Transform triggers
testComp.Scale(0.4, 507, factor=2.0, divide=False, t=1.0, type=1, rate=1.0)
testComp.Scale(0.45, 508, factor=2.0, divide=True, t=1.0, type=1, rate=1.0)

# Visual triggers
testComp.Pulse(0.5, 509, rgb(4,4,4), exclusive=False, fadeIn=0.3, t=1.0, fadeOut=0.3)
testComp.Alpha(0.55, 510, opacity=50, t=0.8)
testComp.Follow(0.6, 511, e.PLR, t=2.0)

# Control triggers
testComp.Stop(0.65, 512)
testComp.Pause(0.7, 513, useControlID=True)
testComp.Resume(0.75, 513, useControlID=True)

# Caller component
callerComp = (Component("MainCaller", group(36))
    .assert_spawn_order(True)
    .Toggle(0, 110, True)
    .Spawn(0.1, testComp.callerGroup, True)
)

# Spawn limit checking test cases

# === Valid cases (should NOT raise errors) ===

# Valid: Unmapped spawns with different targets
valid1 = Component("Valid_DifferentTargets", unknown_g())
valid1.Spawn(0, 601, False)
valid1.Spawn(0, 602, False)  # Different target, OK

# Valid: Unmapped spawns with spawn delay
valid2 = Component("Valid_WithDelay", unknown_g())
valid2.Spawn(0, 603, False)
valid2.Spawn(0, 603, False, delay=0.1)  # Has delay, OK

# Valid: Unmapped spawns at different X positions with requireSpawnOrder
valid3 = Component("Valid_DifferentXPositions", unknown_g())
valid3.assert_spawn_order(True)
valid3.Spawn(0, 604, False)
valid3.Spawn(0.1, 604, False)  # Different X, OK

# Valid: Single unmapped spawn (not multiple)
valid4 = Component("Valid_SingleSpawn", unknown_g())
valid4.Spawn(0, 605, False)

# Valid: Target group has no spawn triggers
valid5_target = Component("Valid_TargetNoSpawn", 606)
valid5_target.Toggle(0, 700, True)  # Not a spawn trigger

valid5 = Component("Valid_TargetHasNoSpawn", unknown_g())
valid5.Spawn(0, 606, False)
valid5.Spawn(0, 606, False)  # OK because 606 has no spawns

# Valid: Remapped spawn with single layer 2 spawn
valid6_layer2 = Component("Valid_SingleLayer2", 607)
valid6_layer2.Spawn(0, 608, False)

valid6 = Component("Valid_RemapSingleLayer2", unknown_g())
valid6.Spawn(0, 500, False, remap="500.607")

# Valid: Multitarget usage without spawn triggers (proper usage)
valid7_target = Component("Valid_MultitargetTarget", 800)
valid7_target.Toggle(0, 900, True)  # No spawn trigger, OK
valid7_target.MoveBy(0, 901, dx=10, dy=0)

valid7 = Component("Valid_Multitarget", unknown_g())
# Get multitarget components for 3 targets
mt_comps = Multitarget.get_binary_components(3, valid7_target)

for mt_comp in mt_comps:
    # Build remap string for each multitarget component
    remap_builder = Remap()
    for spawn_trigger in mt_comp.triggers:
        remap_string = str(spawn_trigger.get(e.Properties.REMAP_STRING, ""))
        if remap_string:
            remap_pairs, _ = translate_remap_string(remap_string)
            for source, target in remap_pairs.items():
                source_num = int(source)
                if source_num == e.EMPTY_BULLET:
                    remap_builder.pair(int(target), 5001)
                elif source_num == e.EMPTY_TARGET_GROUP:
                    remap_builder.pair(int(target), 5002)
                else:
                    remap_builder.pair(int(target), 5003)
    
    # Final mapping: EMPTY_MULTITARGET -> target component
    remap_builder.pair(e.EMPTY_MULTITARGET, valid7_target.callerGroup)
    valid7.Spawn(0, mt_comp.callerGroup, False, remap=remap_builder.build())

# === Invalid cases (SHOULD raise errors) - COMMENTED OUT ===

# # Case 2: Multiple unmapped spawns -> spawn trigger (same tick)
# invalid_case2_target = Component("Invalid_Case2_Target", 701)
# invalid_case2_target.Spawn(0, 702, False)

# invalid_case2 = Component("Invalid_Case2", unknown_g())
# invalid_case2.Spawn(0, 701, False)
# invalid_case2.Spawn(0, 701, False)  # ERROR: 2 unmapped spawns target 701 (has spawn)

# # Case 2: Multiple unmapped spawns at same X with requireSpawnOrder=False
# invalid_case2b_target = Component("Invalid_Case2b_Target", 703)
# invalid_case2b_target.Spawn(0, 704, False)

# invalid_case2b = Component("Invalid_Case2b", unknown_g())
# invalid_case2b.assert_spawn_order(False)
# invalid_case2b.Spawn(0, 703, False)
# invalid_case2b.Spawn(0.5, 703, False)  # ERROR: Different X but requireSpawnOrder=False

# # Case 1: Remapped spawn -> multiple spawns -> spawn trigger (same tick)
# invalid_case1_layer3 = Component("Invalid_Case1_Layer3", 705)
# invalid_case1_layer3.Spawn(0, 706, False)

# invalid_case1_layer2 = Component("Invalid_Case1_Layer2", 707)
# invalid_case1_layer2.Spawn(0, 705, False)
# invalid_case1_layer2.Spawn(0, 705, False)  # 2 spawns target 705

# invalid_case1 = Component("Invalid_Case1", unknown_g())
# invalid_case1.Spawn(0, 500, False, remap="500.707")  # ERROR: Activates layer2 which has multiple spawns to 705

# Case 1: Remapped spawn with multiple remapped targets
# invalid_case1b_layer3 = Component("Invalid_Case1b_Layer3", 708)
# invalid_case1b_layer3.Spawn(0, 709, False)

# invalid_case1b_layer2a = Component("Invalid_Case1b_Layer2a", 710)
# invalid_case1b_layer2a.Spawn(0, 708, False)

# invalid_case1b_layer2b = Component("Invalid_Case1b_Layer2b", 711)
# invalid_case1b_layer2b.Spawn(0, 708, False)

# invalid_case1b = Component("Invalid_Case1b", unknown_g())
# invalid_case1b.Spawn(0, 500, False, remap="500.710.501.711")  # ERROR: 710 and 711 both spawn 708

print("\n=== Spawn Limit Test Cases ===")
print("Valid cases loaded successfully")
print("Invalid cases commented out - uncomment one at a time to test")

save_all()
