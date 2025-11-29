# pyright: reportTypedDictNotRequiredAccess=false
# pyright: reportArgumentType=false
# pyright: reportPrivateUsage=false
"""
Focused unit tests for trigger methods in Component class.

Philosophy: Tests should expose logic bugs and verify validation.
- Test parameter boundaries that should be rejected
- Test edge cases at validation limits
- Verify error messages are correct
- Skip trivial tests that just verify property assignment
"""

import pytest
from pytest import ExceptionInfo
from touhou_scs.component import Component
from touhou_scs import enums, lib, utils


def assert_error(exc_info: ExceptionInfo[BaseException], *patterns: str) -> None:
    """Assert exception message contains all patterns."""
    msg_clean = str(exc_info.value).lower().replace(" ", "")
    for pattern in patterns:
        p = pattern.lower().replace(" ", "")
        assert p in msg_clean, f"Expected '{pattern}' in: {str(exc_info.value)}"


# ============================================================================
# SPAWN TRIGGER - Target Group Validation
# ============================================================================

class TestSpawnTargetValidation:
    """Test Spawn target group validation boundaries"""
    
    def test_spawn_target_zero_rejected(self):
        """Target group 0 is out of valid range"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc: 
            comp.Spawn(0, 0, spawnOrdered=False)
        assert_error(exc, "out of valid range", "0")
    
    def test_spawn_target_negative_rejected(self):
        """Negative target groups are rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Spawn(0, -50, spawnOrdered=False)
        assert_error(exc, "out of valid range", "-50")
    
    def test_spawn_target_10_valid(self):
        """Target group 10 is valid (non-restricted)"""
        comp = Component("Test", 100)
        comp.Spawn(0, 10, spawnOrdered=False)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.TARGET] == 10
    
    def test_spawn_target_at_counter_valid(self):
        """Target at unknown_g.counter boundary is valid"""
        comp = Component("Test", 100)
        max_valid = utils.unknown_g.counter
        comp.Spawn(0, max_valid, spawnOrdered=False)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.TARGET] == max_valid
    
    def test_spawn_target_above_counter_rejected(self):
        """Target above unknown_g.counter is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Spawn(0, utils.unknown_g.counter + 1, spawnOrdered=False)
        assert_error(exc, "out of valid range")
    
    def test_spawn_restricted_group_rejected(self):
        """Restricted groups are rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Spawn(0, 3, spawnOrdered=False)
        assert_error(exc, "restricted", "3")


class TestSpawnDelayValidation:
    """Test Spawn delay parameter behavior"""
    
    def test_spawn_negative_delay_rejected(self):
        """Negative delay is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Spawn(0, 50, spawnOrdered=False, delay=-1)
        assert_error(exc, "non-negative", "-1")
    
    def test_spawn_zero_delay_not_stored(self):
        """Zero delay is not stored"""
        comp = Component("Test", 100)
        comp.Spawn(0, 50, spawnOrdered=False, delay=0)
        trigger = comp.triggers[0]
        assert enums.Properties.SPAWN_DELAY not in trigger
    
    def test_spawn_positive_delay_stored(self):
        """Positive delay is stored"""
        comp = Component("Test", 100)
        comp.Spawn(0, 50, spawnOrdered=False, delay=0.5)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.SPAWN_DELAY] == 0.5


class TestSpawnRemapValidation:
    """Test remap string handling"""
    
    def test_spawn_remap_empty_string_not_stored(self):
        """Empty remap string is silently skipped"""
        comp = Component("Test", 100)
        comp.Spawn(0, 50, spawnOrdered=False, remap="")
        trigger = comp.triggers[0]
        assert enums.Properties.REMAP_STRING not in trigger
    
    def test_spawn_remap_odd_pairs_rejected(self):
        """Odd number of remap values is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Spawn(0, 50, spawnOrdered=False, remap="1.2.3")
        assert_error(exc, "even number")
    
    def test_spawn_remap_duplicate_source_rejected(self):
        """Remapping same source to different targets is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Spawn(0, 50, spawnOrdered=False, remap="10.20.10.30")
        assert_error(exc, "Duplicate source", "10")


# ============================================================================
# MOVE TRIGGERS - Easing Boundaries
# ============================================================================

class TestMoveEasingValidation:
    """Test Move trigger easing parameter boundaries"""
    
    def test_easing_type_negative_rejected(self):
        """Negative easing type is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, type=-1)
        assert_error(exc, "type", "-1")
    
    def test_easing_type_19_rejected(self):
        """Easing type 19 (above max 18) is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, type=19)
        assert_error(exc, "type", "19")
    
    def test_easing_type_0_valid(self):
        """Easing type 0 (NONE) is valid"""
        comp = Component("Test", 100)
        comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, type=0)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.EASING] == 0
    
    def test_easing_type_18_valid(self):
        """Easing type 18 (max) is valid"""
        comp = Component("Test", 100)
        comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, type=18)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.EASING] == 18
    
    def test_easing_rate_0_10_rejected(self):
        """Easing rate at 0.10 is rejected (must be > 0.10)"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, rate=0.10)
        assert_error(exc, "rate", "0.1")
    
    def test_easing_rate_below_0_10_rejected(self):
        """Easing rate below 0.10 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, rate=0.05)
        assert_error(exc, "rate", "0.05")
    
    def test_easing_rate_above_20_rejected(self):
        """Easing rate above 20.0 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, rate=20.01)
        assert_error(exc, "rate", "20.01")
    
    def test_easing_rate_20_valid(self):
        """Easing rate 20.0 is valid (upper boundary)"""
        comp = Component("Test", 100)
        comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, rate=20.0)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.EASING_RATE] == 20.0
    
    def test_easing_rate_just_above_0_10_valid(self):
        """Easing rate just above 0.10 is valid"""
        comp = Component("Test", 100)
        comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, rate=0.11)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.EASING_RATE] == 0.11
    
    def test_easing_type_float_non_integer_rejected(self):
        """Easing type as non-integer float is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.MoveTowards(0, target=50, targetDir=60, t=1.0, dist=100, type=2.5)
        assert_error(exc, "type", "2.5")


class TestMoveDurationValidation:
    """Test Move trigger duration validation"""
    
    def test_duration_negative_rejected(self):
        """Negative duration is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.MoveTowards(0, target=50, targetDir=60, t=-0.5, dist=100)
        assert_error(exc, "non-negative", "-0.5")
    
    def test_duration_zero_sets_silent(self):
        """Duration zero sets MOVE_SILENT flag"""
        comp = Component("Test", 100)
        comp.MoveTowards(0, target=50, targetDir=60, t=0, dist=100)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.MOVE_SILENT] is True
    
    def test_duration_positive_no_silent(self):
        """Positive duration doesn't set MOVE_SILENT flag"""
        comp = Component("Test", 100)
        comp.MoveTowards(0, target=50, targetDir=60, t=0.5, dist=100)
        trigger = comp.triggers[0]
        assert enums.Properties.MOVE_SILENT not in trigger


# ============================================================================
# ALPHA TRIGGER - Opacity Boundaries
# ============================================================================

class TestAlphaOpacityValidation:
    """Test Alpha trigger opacity boundaries"""
    
    def test_opacity_negative_rejected(self):
        """Negative opacity is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Alpha(0, target=50, opacity=-1)
        assert_error(exc, "between 0 and 100")
    
    def test_opacity_above_100_rejected(self):
        """Opacity above 100 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Alpha(0, target=50, opacity=101)
        assert_error(exc, "between 0 and 100")
    
    def test_opacity_0_valid(self):
        """Opacity 0 (fully transparent) is valid"""
        comp = Component("Test", 100)
        comp.Alpha(0, target=50, opacity=0)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.OPACITY] == 0.0
    
    def test_opacity_100_valid(self):
        """Opacity 100 (fully opaque) is valid"""
        comp = Component("Test", 100)
        comp.Alpha(0, target=50, opacity=100)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.OPACITY] == 1.0
    
    def test_opacity_converts_to_decimal(self):
        """Opacity 50 converts to 0.5"""
        comp = Component("Test", 100)
        comp.Alpha(0, target=50, opacity=50)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.OPACITY] == 0.5


# ============================================================================
# SCALE TRIGGER - Factor Validation
# ============================================================================

class TestScaleFactorValidation:
    def test_scale_factor_zero_rejected(self):
        """Scale factor 0 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Scale(0, target=50, factor=0, t=1.0)
        assert_error(exc, "factor", ">0", "0")
    
    def test_scale_factor_negative_rejected(self):
        """Negative scale factor is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Scale(0, target=50, factor=-1.0, t=1.0)
        assert_error(exc, "factor", ">0", "-1")
    
    def test_scale_factor_one_rejected(self):
        """Scale factor 1.0 (no change) is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Scale(0, target=50, factor=1.0, t=1.0)
        assert_error(exc, "1", "has no effect")
    
    def test_scale_factor_barely_above_one_valid(self):
        """Scale factor just above 1.0 is valid"""
        comp = Component("Test", 100)
        comp.Scale(0, target=50, factor=1.0001, t=1.0)
        assert len(comp.triggers) == 1
    
    def test_scale_factor_barely_below_one_valid(self):
        """Scale factor just below 1.0 is valid"""
        comp = Component("Test", 100)
        comp.Scale(0, target=50, factor=0.9999, t=1.0)
        assert len(comp.triggers) == 1
    
    def test_scale_hold_negative_rejected(self):
        """Negative hold time is rejected via duration validation"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Scale(0, target=50, factor=2.0, t=1.0, hold=-5.0)
        assert_error(exc, "non-negative", "-5")


# ============================================================================
# COUNT TRIGGER - Item ID Validation
# ============================================================================

class TestCountItemIdValidation:
    """Test Count trigger item ID validation"""
    
    def test_count_item_id_zero_rejected(self):
        """Item ID 0 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Count(0, 10, item_id=0, count=100, activateGroup=True)
        assert_error(exc, "positive", "0")
    
    def test_count_item_id_negative_rejected(self):
        """Negative item ID is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Count(0, 10, item_id=-5, count=100, activateGroup=True)
        assert_error(exc, "positive", "-5")
    
    def test_count_item_id_above_9999_rejected(self):
        """Item ID above 9999 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Count(0, 10, item_id=10000, count=100, activateGroup=True)
        assert_error(exc, "positive", "10000")
    
    def test_count_item_id_1_valid(self):
        """Item ID 1 (lower boundary) is valid"""
        comp = Component("Test", 100)
        comp.Count(0, 10, item_id=1, count=100, activateGroup=True)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.ITEM_ID] == 1
    
    def test_count_item_id_9999_valid(self):
        """Item ID 9999 (upper boundary) is valid"""
        comp = Component("Test", 100)
        comp.Count(0, 10, item_id=9999, count=100, activateGroup=True)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.ITEM_ID] == 9999


# ============================================================================
# PICKUP TRIGGER - Validation
# ============================================================================

class TestPickupValidation:
    """Test Pickup trigger validation"""
    
    def test_pickup_item_id_zero_rejected(self):
        """Item ID 0 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Pickup(0, item_id=0, count=50, override=False)
        assert_error(exc, "positive", "0")
    
    def test_pickup_item_id_negative_rejected(self):
        """Negative item ID is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Pickup(0, item_id=-10, count=50, override=False)
        assert_error(exc, "positive", "-10")
    
    def test_pickup_item_id_above_9999_rejected(self):
        """Item ID above 9999 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Pickup(0, item_id=10000, count=50, override=False)
        assert_error(exc, "positive", "10000")
    
    def test_pickup_count_zero_rejected(self):
        """Count of 0 (no change) is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Pickup(0, item_id=5, count=0, override=False)
        assert_error(exc, "no change", "0")
    
    def test_pickup_count_negative_allowed(self):
        """Negative count (subtract items) is allowed"""
        comp = Component("Test", 100)
        comp.Pickup(0, item_id=5, count=-50, override=False)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.PICKUP_COUNT] == -50
    
    def test_pickup_no_target_property(self):
        """Pickup trigger should not have TARGET property"""
        comp = Component("Test", 100)
        comp.Pickup(0, item_id=5, count=50, override=False)
        trigger = comp.triggers[0]
        assert enums.Properties.TARGET not in trigger


# ============================================================================
# PICKUP MODIFY TRIGGER - Validation
# ============================================================================

class TestPickupModifyValidation:
    """Test PickupModify trigger validation"""
    
    def test_pickup_modify_item_id_zero_rejected(self):
        """Item ID 0 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PickupModify(0, item_id=0, factor=1.5, multiply=True)
        assert_error(exc, "positive", "0")
    
    def test_pickup_modify_item_id_above_9999_rejected(self):
        """Item ID above 9999 is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PickupModify(0, item_id=10000, factor=1.5, multiply=True)
        assert_error(exc, "positive", "10000")
    
    def test_pickup_modify_factor_one_rejected(self):
        """Factor of 1 (no effect) is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PickupModify(0, item_id=5, factor=1, multiply=True)
        assert_error(exc, "1 has no effect")
    
    def test_pickup_modify_factor_one_float_rejected(self):
        """Factor of 1.0 (no effect) is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PickupModify(0, item_id=5, factor=1.0, multiply=True)
        assert_error(exc, "1 has no effect")
    
    def test_pickup_modify_no_mode_rejected(self):
        """Neither multiply nor divide specified is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PickupModify(0, item_id=5, factor=1.5)
        assert_error(exc, "multiply", "divide")
    
    def test_pickup_modify_both_modes_rejected(self):
        """Both multiply and divide specified is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PickupModify(0, item_id=5, factor=1.5, multiply=True, divide=True)
        assert_error(exc, "both", "multiply", "divide")
    
    def test_pickup_modify_multiply_mode_value(self):
        """Multiply mode sets PICKUP_MULTIPLY_DIVIDE to 1"""
        comp = Component("Test", 100)
        comp.PickupModify(0, item_id=5, factor=1.5, multiply=True)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.PICKUP_MULTIPLY_DIVIDE] == 1
    
    def test_pickup_modify_divide_mode_value(self):
        """Divide mode sets PICKUP_MULTIPLY_DIVIDE to 2"""
        comp = Component("Test", 100)
        comp.PickupModify(0, item_id=5, factor=2.0, divide=True)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.PICKUP_MULTIPLY_DIVIDE] == 2
    
    def test_pickup_modify_no_target_property(self):
        """PickupModify trigger should not have TARGET property"""
        comp = Component("Test", 100)
        comp.PickupModify(0, item_id=5, factor=1.5, multiply=True)
        trigger = comp.triggers[0]
        assert enums.Properties.TARGET not in trigger


# ============================================================================
# ROTATE / POINT TO GROUP - Dynamic + Easing
# ============================================================================

class TestPointToGroupValidation:
    """Test PointToGroup dynamic + easing conflict"""
    
    def test_point_to_group_dynamic_with_easing_type_rejected(self):
        """Dynamic mode with easing type is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PointToGroup(0, target=50, targetDir=60, dynamic=True, type=3)
        assert_error(exc, "dynamic", "easing", "3")
    
    def test_point_to_group_dynamic_with_easing_rate_rejected(self):
        """Dynamic mode with non-default easing rate is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.PointToGroup(0, target=50, targetDir=60, dynamic=True, rate=1.5)
        assert_error(exc, "dynamic", "easing", "1.5")
    
    def test_point_to_group_dynamic_without_easing_valid(self):
        """Dynamic mode without easing is valid"""
        comp = Component("Test", 100)
        comp.PointToGroup(0, target=50, targetDir=60, dynamic=True)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.DYNAMIC] is True
    
    def test_point_to_group_static_with_easing_valid(self):
        """Static mode with easing is valid"""
        comp = Component("Test", 100)
        comp.PointToGroup(0, target=50, targetDir=60, dynamic=False, type=3, rate=1.5)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.EASING] == 3
        assert trigger[enums.Properties.EASING_RATE] == 1.5


class TestRotateValidation:
    """Test Rotate trigger validation"""
    
    def test_rotate_center_defaults_to_target(self):
        """Center defaults to target when not specified"""
        comp = Component("Test", 100)
        comp.Rotate(0, target=50, angle=90)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.ROTATE_CENTER] == 50
    
    def test_rotate_center_can_differ_from_target(self):
        """Center can be different from target"""
        comp = Component("Test", 100)
        comp.Rotate(0, target=50, angle=90, center=60)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.TARGET] == 50
        assert trigger[enums.Properties.ROTATE_CENTER] == 60
    
    def test_rotate_restricted_center_rejected(self):
        """Restricted center group is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.Rotate(0, target=50, angle=90, center=3)
        assert_error(exc, "restricted", "3")


# ============================================================================
# GROUP CONTEXT - State Management
# ============================================================================

class TestGroupContextManagement:
    """Test group context state management - could easily corrupt state"""
    
    def test_start_context_adds_groups_to_subsequent_triggers(self):
        """Triggers after start_group_context include context groups"""
        comp = Component("Test", 100)
        comp.start_group_context(200)
        comp.Toggle(0, 50, activateGroup=True)
        trigger = comp.triggers[0]
        assert 200 in trigger[enums.Properties.GROUPS]
    
    def test_end_context_removes_context_groups(self):
        """Triggers after end_group_context exclude context groups"""
        comp = Component("Test", 100)
        comp.start_group_context(200)
        comp.Toggle(0, 50, activateGroup=True)
        comp.end_group_context()
        comp.Toggle(0.1, 51, activateGroup=True)
        
        assert 200 in comp.triggers[0][enums.Properties.GROUPS]
        assert 200 not in comp.triggers[1][enums.Properties.GROUPS]
    
    def test_nested_context_rejected(self):
        """Starting context while one is active is rejected"""
        comp = Component("Test", 100)
        comp.start_group_context(200)
        with pytest.raises(RuntimeError) as exc:
            comp.start_group_context(300)
        assert_error(exc, "already has an active group context")
    
    def test_end_without_start_rejected(self):
        """Ending context without starting is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(RuntimeError) as exc:
            comp.end_group_context()
        assert_error(exc, "no active group context")
    
    def test_context_with_multiple_groups(self):
        """Context can add multiple groups at once"""
        comp = Component("Test", 100)
        comp.start_group_context(200, 201, 202)
        comp.Toggle(0, 50, activateGroup=True)
        trigger = comp.triggers[0]
        assert all(g in trigger[enums.Properties.GROUPS] for g in [200, 201, 202])
    
    def test_context_with_list_groups(self):
        """Context accepts list of groups"""
        comp = Component("Test", 100)
        comp.start_group_context([200, 201])
        comp.Toggle(0, 50, activateGroup=True)
        trigger = comp.triggers[0]
        assert 200 in trigger[enums.Properties.GROUPS]
        assert 201 in trigger[enums.Properties.GROUPS]
    
    def test_context_empty_rejected(self):
        """Starting context with no groups is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.start_group_context()
        assert_error(exc, "at least one group")


class TestGroupLastTrigger:
    """Test group_last_trigger method"""
    
    def test_group_last_trigger_adds_to_most_recent(self):
        """group_last_trigger adds groups to the last trigger only"""
        comp = Component("Test", 100)
        comp.Toggle(0, 50, activateGroup=True)
        comp.Toggle(0.1, 51, activateGroup=True)
        comp.group_last_trigger(300)
        
        assert 300 not in comp.triggers[0][enums.Properties.GROUPS]
        assert 300 in comp.triggers[1][enums.Properties.GROUPS]
    
    def test_group_last_trigger_no_triggers_rejected(self):
        """Grouping when no triggers exist is rejected"""
        comp = Component("Test", 100)
        with pytest.raises(RuntimeError) as exc:
            comp.group_last_trigger(300)
        assert_error(exc, "no triggers")
    
    def test_group_last_trigger_duplicate_rejected(self):
        """Adding duplicate group to trigger is rejected"""
        comp = Component("Test", 100)
        comp.Toggle(0, 50, activateGroup=True)
        comp.group_last_trigger(300)
        with pytest.raises(ValueError, match="duplicate"):
            comp.group_last_trigger(300)
    
    def test_group_last_trigger_empty_rejected(self):
        """Grouping with no groups is rejected"""
        comp = Component("Test", 100)
        comp.Toggle(0, 50, activateGroup=True)
        with pytest.raises(ValueError) as exc:
            comp.group_last_trigger()
        assert_error(exc, "at least one group")


class TestFlattenGroups:
    """Test _flatten_groups duplicate detection"""
    
    def test_flatten_detects_duplicates_in_single_list(self):
        """Duplicate groups in a list are detected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError, match="Duplicate"):
            comp._flatten_groups([100, 200, 100])
    
    def test_flatten_detects_duplicates_across_args(self):
        """Duplicate groups across multiple args are detected"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError, match="Duplicate"):
            comp._flatten_groups(100, [200, 100])


# ============================================================================
# INSTANT PATTERNS - Spawn Order Requirement
# ============================================================================

class TestInstantPatternSpawnOrderRequirement:
    """Test that instant patterns require spawn order"""
    
    def test_arc_without_spawn_order_rejected(self):
        """Arc without spawn order raises ValueError"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=5, spacing=30
            )
        assert_error(exc, "must require spawn order")
    
    def test_radial_without_spawn_order_rejected(self):
        """Radial without spawn order raises ValueError"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.instant.Radial(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=12
            )
        assert_error(exc, "must require spawn order")
    
    def test_line_without_spawn_order_rejected(self):
        """Line without spawn order raises ValueError"""
        comp = Component("Test", 100)
        with pytest.raises(ValueError) as exc:
            comp.instant.Line(
                time=0, comp=comp, targetDir=90, bullet=lib.bullet2,
                numBullets=5, fastestTime=0.5, slowestTime=2.0, dist=100
            )
        assert_error(exc, "must require spawn order")


# ============================================================================
# INSTANT ARC PATTERN - Complex Validation Logic
# ============================================================================

class TestInstantArcValidation:
    """Test Arc pattern validation - complex math that could break"""
    
    def test_arc_odd_bullets_fractional_center_rejected(self):
        """Odd bullets with fractional centerAt is rejected"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=5, spacing=30, centerAt=45.5
            )
        assert_error(exc, "odd bullets requires integer centerAt")
    
    def test_arc_even_bullets_odd_spacing_integer_center_rejected(self):
        """Even bullets with odd spacing requires .5 centerAt"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=4, spacing=15, centerAt=0
            )
        assert_error(exc, "even", "odd spacing", ".5")
    
    def test_arc_even_bullets_even_spacing_fractional_center_rejected(self):
        """Even bullets with even spacing requires integer centerAt"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=4, spacing=30, centerAt=45.5
            )
        assert_error(exc, "even bullets with even spacing requires integer centerAt")
    
    def test_arc_spacing_zero_rejected(self):
        """Spacing below 1 is rejected"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=5, spacing=0
            )
        assert_error(exc, "spacing", "1", "360", "0")
    
    def test_arc_spacing_above_360_rejected(self):
        """Spacing above 360 is rejected"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=1, spacing=361
            )
        assert_error(exc, "spacing must be between 1 and 360")
    
    def test_arc_exceeds_360_degrees_rejected(self):
        """numBullets * spacing > 360 is rejected"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=10, spacing=40  # 10 * 40 = 400 > 360
            )
        assert_error(exc, "exceeds 360")
    
    def test_arc_center_at_invalid_fraction_rejected(self):
        """centerAt must be integer or .5 increments"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Arc(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=5, spacing=30, centerAt=45.3, radialBypass=True  # bypass arc logic to hit generic check
            )
        assert_error(exc, "centerAt must be an integer or integer.5")


# ============================================================================
# INSTANT RADIAL PATTERN - Validation
# ============================================================================

class TestInstantRadialValidation:
    """Test Radial pattern validation"""
    
    def test_radial_neither_spacing_nor_numbullets_rejected(self):
        """Must provide either spacing or numBullets"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Radial(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1
            )
        assert_error(exc, "must provide", "spacing", "numBullets")
    
    def test_radial_mismatched_spacing_and_numbullets_rejected(self):
        """spacing and numBullets must be consistent"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Radial(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=12, spacing=20  # 360/20 = 18, not 12
            )
        assert_error(exc, "don't match")
    
    def test_radial_non_factor_of_360_spacing_rejected(self):
        """Spacing must be a factor of 360"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Radial(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                spacing=7  # 7 is not a factor of 360
            )
        assert_error(exc, "factor of 360", "7")
    
    def test_radial_non_factor_of_360_numbullets_rejected(self):
        """numBullets must be a factor of 360"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Radial(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                numBullets=7  # 7 is not a factor of 360
            )
        assert_error(exc, "factor of 360")


# ============================================================================
# INSTANT LINE PATTERN - Validation
# ============================================================================

class TestInstantLineValidation:
    """Test Instant Line pattern validation"""
    
    def test_line_fastest_zero_rejected(self):
        """fastestTime must be positive"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc: 
            caller.instant.Line(
                time=0, comp=comp, targetDir=90, bullet=lib.bullet2,
                numBullets=5, fastestTime=0, slowestTime=2.0, dist=100
            )
        assert_error(exc, "positive", "0")
    
    def test_line_slowest_not_greater_than_fastest_rejected(self):
        """slowestTime must be greater than fastestTime"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc: 
            caller.instant.Line(
                time=0, comp=comp, targetDir=90, bullet=lib.bullet2,
                numBullets=5, fastestTime=2.0, slowestTime=1.0, dist=100
            )
        assert_error(exc, "greater than", "2.0", "1.0")
    
    def test_line_too_few_bullets_rejected(self):
        """numBullets must be at least 3"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.instant.Line(
                time=0, comp=comp, targetDir=90, bullet=lib.bullet2,
                numBullets=2, fastestTime=0.5, slowestTime=2.0, dist=100
            )
        assert_error(exc, "numBullets must be at least 3")


# ============================================================================
# TIMED PATTERNS - Validation
# ============================================================================

class TestTimedRadialWaveValidation:
    """Test RadialWave pattern validation"""
    
    def test_radial_wave_zero_waves_rejected(self):
        """waves must be at least 1"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.timed.RadialWave(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                waves=0, numBullets=12
            )
        assert_error(exc, "waves must be at least 1")
    
    def test_radial_wave_single_wave_rejected(self):
        """Single wave should use instant.Radial instead"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc:
            caller.timed.RadialWave(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                waves=1, numBullets=12
            )
        assert_error(exc, "use instant.Radial")
    
    def test_radial_wave_negative_interval_rejected(self):
        """interval must be non-negative"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        comp.Toggle(0, enums.EMPTY_TARGET_GROUP, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError) as exc: 
            caller.timed.RadialWave(
                time=0, comp=comp, gc=lib.circle1, bullet=lib.bullet1,
                waves=3, interval=-0.5, numBullets=12
            )
        assert_error(exc, "non-negative", "-0.5")


class TestTimedLineValidation:
    """Test Timed Line pattern validation"""
    
    def test_timed_line_too_few_bullets_rejected(self):
        """numBullets must be at least 2"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError, match="numBullets must be at least 2"):
            caller.timed.Line(
                time=0, comp=comp, targetDir=90, bullet=lib.bullet2,
                numBullets=1, spacing=0.5, t=1.0, dist=100
            )
    
    def test_timed_line_negative_spacing_rejected(self):
        """spacing must be non-negative"""
        comp = Component("Test", 100).assert_spawn_order(True)
        comp.Toggle(0, enums.EMPTY_BULLET, activateGroup=True)
        
        caller = Component("Caller", 200)
        with pytest.raises(ValueError, match="spacing must be non-negative"):
            caller.timed.Line(
                time=0, comp=comp, targetDir=90, bullet=lib.bullet2,
                numBullets=5, spacing=-0.5, t=1.0, dist=100
            )


# ============================================================================
# METHOD CHAINING - Return Self
# ============================================================================

class TestMethodChainingReturnsSelf:
    """Test that trigger methods return self for chaining"""
    
    def test_spawn_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Spawn(0, 50, spawnOrdered=False)
        assert result is comp
    
    def test_toggle_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Toggle(0, 50, activateGroup=True)
        assert result is comp
    
    def test_count_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Count(0, 10, item_id=5, count=100, activateGroup=True)
        assert result is comp
    
    def test_pickup_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Pickup(0, item_id=5, count=50, override=False)
        assert result is comp
    
    def test_pickup_modify_returns_self(self):
        comp = Component("Test", 100)
        result = comp.PickupModify(0, item_id=5, factor=1.5, multiply=True)
        assert result is comp
    
    def test_move_by_returns_self(self):
        comp = Component("Test", 100)
        result = comp.MoveBy(0, target=50, dx=10, dy=20)
        assert result is comp
    
    def test_rotate_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Rotate(0, target=50, angle=90)
        assert result is comp
    
    def test_stop_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Stop(0, target=50)
        assert result is comp
    
    def test_pause_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Pause(0, target=50)
        assert result is comp
    
    def test_resume_returns_self(self):
        comp = Component("Test", 100)
        result = comp.Resume(0, target=50)
        assert result is comp
    
    def test_chain_preserves_trigger_count(self):
        """Chained calls accumulate triggers"""
        comp = Component("Test", 100)
        (comp
            .Toggle(0, 50, activateGroup=True)
            .Alpha(0.1, 50, opacity=50)
            .MoveBy(0.2, target=50, dx=10, dy=20)
        )
        assert len(comp.triggers) == 3
    
    def test_group_context_returns_self(self):
        """Group context methods support chaining"""
        comp = Component("Test", 100)
        result = comp.start_group_context(200).Toggle(0, 50, activateGroup=True).end_group_context()
        assert result is comp
        assert len(comp.triggers) == 1


# ============================================================================
# COMPONENT TARGET ACCEPTS COMPONENT OBJECTS
# ============================================================================

class TestComponentAsTarget:
    """Test that methods accept Component objects as targets"""
    
    def test_spawn_accepts_component(self):
        """Spawn can target a Component directly"""
        target_comp = Component("Target", 150)
        comp = Component("Test", 100)
        comp.Spawn(0, target_comp, spawnOrdered=False)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.TARGET] == 150
    
    def test_toggle_accepts_component(self):
        """Toggle can target a Component directly"""
        target_comp = Component("Target", 150)
        comp = Component("Test", 100)
        comp.Toggle(0, target_comp, activateGroup=True)
        trigger = comp.triggers[0]
        assert trigger[enums.Properties.TARGET] == 150
