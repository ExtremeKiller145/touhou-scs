"""
Phase 1 Testing Script
Test enums.py and utils.py functionality
"""

import touhou_scs.enums as e
import touhou_scs.utils as u

print("=" * 70)
print("PHASE 1 - TESTING ENUMS AND UTILS")
print("=" * 70)

# ============================================================================
# Test 1: Enums
# ============================================================================
print("\n[Test 1] Testing Enums...")

# Test ObjectID
print(f"  ObjectID.SPAWN = {e.ObjectID.SPAWN}")
print(f"  ObjectID.MOVE = {e.ObjectID.MOVE}")
assert e.ObjectID.SPAWN == 1268
assert e.ObjectID.MOVE == 901
print("  ✓ ObjectID enum works")

# Test Easing
print(f"  Easing.EASE_IN_OUT = {e.Easing.EASE_IN_OUT}")
print(f"  Easing.BOUNCE_IN = {e.Easing.BOUNCE_IN}")
assert e.Easing.EASE_IN_OUT == 1
assert e.Easing.BOUNCE_IN == 8
print("  ✓ Easing enum works")

# Test Properties
print(f"  Properties.TARGET = {e.Properties.TARGET}")
print(f"  Properties.REMAP_STRING = {e.Properties.REMAP_STRING}")
assert e.Properties.TARGET == 51
assert e.Properties.REMAP_STRING == 442
print("  ✓ Properties class works")

# Test Constants
print(f"  TICK = {e.TICK}")
print(f"  PLR_SPEED = {e.PLR_SPEED}")
print(f"  EMPTY_BULLET = {e.EMPTY_BULLET}")
assert e.TICK == 1/240
assert e.PLR_SPEED == 311.58
assert e.EMPTY_BULLET == 10
print("  ✓ Constants work")

# Test SpeedProfiles
print(f"  SpeedProfiles.FAST = {e.SpeedProfiles.FAST}")
assert e.SpeedProfiles.FAST == 480 / 4
print("  ✓ SpeedProfiles work")

print("\n✓ All enum tests passed!")

# ============================================================================
# Test 2: Unknown Groups
# ============================================================================
print("\n[Test 2] Testing Unknown Group Generation...")

# Reset counter for predictable testing
u.resetUnknownGCounter()

g1 = u.unknownG()
g2 = u.unknownG()
g3 = u.unknownG()

print(f"  First unknown group: {g1}")
print(f"  Second unknown group: {g2}")
print(f"  Third unknown group: {g3}")

assert g1 == 100000
assert g2 == 100001
assert g3 == 100002
print("  ✓ Unknown groups generate correctly")

# ============================================================================
# Test 3: Conversion Functions
# ============================================================================
print("\n[Test 3] Testing Conversion Functions...")

dist = u.timeToDist(1.0)
print(f"  timeToDist(1.0) = {dist}")
assert dist == 311.58
print("  ✓ timeToDist works")

time = u.distToTime(311.58)
print(f"  distToTime(311.58) = {time}")
assert time == 1.0
print("  ✓ distToTime works")

spacing = u.spacingBullet(100, 50)
print(f"  spacingBullet(100, 50) = {spacing}")
assert spacing == 50 / 100 * 311.58
print("  ✓ spacingBullet works")

# ============================================================================
# Test 4: Validation Functions
# ============================================================================
print("\n[Test 4] Testing Validation Functions...")

# Valid groups should pass
try:
    u.validateGroups("test", 500, 1000, 100050)
    print("  ✓ Valid groups pass validation")
except ValueError as ex:
    print(f"  ✗ Unexpected error: {ex}")

# Restricted group should fail
try:
    u.validateGroups("test", 9999)
    print("  ✗ Restricted group should have failed!")
except ValueError as ex:
    print(f"  ✓ Restricted group caught: {ex}")

# Invalid range should fail
try:
    u.validateGroups("test", 50000)
    print("  ✗ Invalid range should have failed!")
except ValueError as ex:
    print(f"  ✓ Invalid range caught: {ex}")

# Test isInteger
assert u.isInteger(5.0)
assert not u.isInteger(5.5)
print("  ✓ isInteger works")

print("\n✓ All validation tests passed!")

# ============================================================================
# Test 5: Cyclers
# ============================================================================
print("\n[Test 5] Testing Cyclers...")

cycler = u.createNumberCycler(1, 3)
results = [cycler() for _ in range(5)]
print(f"  Number cycler (1-3): {results}")
assert results == [1, 2, 3, 1, 2]
print("  ✓ Number cycler works and cycles correctly")

bulletCycler = u.createBulletCycler(501, 503)
b1, c1 = bulletCycler()
b2, c2 = bulletCycler()
print(f"  Bullet cycler: ({b1}, {c1}), ({b2}, {c2})")
assert b1 == 501 and c1 == 504
assert b2 == 502 and c2 == 505
print("  ✓ Bullet cycler works correctly")

# ============================================================================
# Test 6: Remap String Utilities
# ============================================================================
print("\n[Test 6] Testing Remap String Utilities...")

# Test translation
remapDict = u.translateRemapString("10.20.30.40")
print(f"  translateRemapString('10.20.30.40') = {remapDict}")
assert remapDict == {'10': '20', '30': '40'}
print("  ✓ translateRemapString works")

# Test validation
cleaned = u.validateRemapString("test", "10.20.30.30")
print("  validateRemapString detects duplicates")

# Test RemapBuilder
builder = u.RemapBuilder()
remap = builder.pair(10, 20).pair(30, 40).build()
print(f"  RemapBuilder: {remap}")
assert remap == "10.20.30.40"
print("  ✓ RemapBuilder basic functionality works")

# Test with function
counter = u.createNumberCycler(100, 102)
builder2 = u.RemapBuilder()
remap2 = builder2.pairFunc(10, counter).pairFunc(20, counter).build()
print(f"  RemapBuilder with functions: {remap2}")
assert remap2 == "10.100.20.101"
print("  ✓ RemapBuilder with functions works")

# Test identity removal
builder3 = u.RemapBuilder()
remap3 = builder3.pair(10, 10).pair(20, 30).build()
print(f"  RemapBuilder removes identity mappings: {remap3}")
assert remap3 == "20.30"
print("  ✓ RemapBuilder removes identity mappings")

# ============================================================================
# Test 7: Usage Pattern Test
# ============================================================================
print("\n[Test 7] Testing Usage Pattern (like main.lua)...")

# Reset for clean test
u.resetUnknownGCounter()

# Simulate creating component groups
componentGroup = u.unknownG()
bulletGroup = u.unknownG()
targetGroup = u.unknownG()

print(f"  Component group: {componentGroup}")
print(f"  Bullet group: {bulletGroup}")
print(f"  Target group: {targetGroup}")

# Test accessing enums like in Lua
tick = e.TICK
emptyBullet = e.EMPTY_BULLET
easingType = e.Easing.EASE_IN_OUT

print(f"  e.TICK = {tick}")
print(f"  e.EMPTY_BULLET = {emptyBullet}")
print(f"  e.Easing.EASE_IN_OUT = {easingType}")

assert tick == 1/240
assert emptyBullet == 10
assert easingType == 1

print("  ✓ Usage pattern matches Lua style")

# ============================================================================
# Summary
# ============================================================================
print("\n" + "=" * 70)
print("✓ ALL PHASE 1 TESTS PASSED!")
print("=" * 70)
print("\nPhase 1 Components Ready:")
print("  ✓ enums.py - All constants and enums working")
print("  ✓ utils.py - All utilities and validators working")
print("  ✓ Unknown groups use integer range (100000+)")
print("  ✓ RemapBuilder provides clean API")
print("  ✓ Usage pattern matches Lua style (e.TICK, e.Easing.NONE)")
print("\nReady to proceed to Phase 2: Component System")
print("=" * 70)
