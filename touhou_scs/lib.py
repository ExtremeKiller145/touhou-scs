"""
Touhou SCS - Library Module

Core infrastructure: Spell system, GuiderCircles, BulletPools, and export functionality.
Module-level storage for components and spells for automatic registration.
"""

import json
import random
import time
from typing import Any
from warnings import warn

from touhou_scs import enums as enum
from touhou_scs.types import ComponentProtocol, SpellProtocol, Trigger


all_spells: list[SpellProtocol] = []
all_components: list[ComponentProtocol] = []

_start_time = time.time()

TRIGGER_AREA = {
    "min_x": 1350,
    "min_y": 1300,
    "max_x": 2000,
    "max_y": 2000
}

class Spell:
    """
    Spell composed of multiple components with a caller group.
    Automatically registers itself in all_spells on creation.
    """
    
    def __init__(self, spell_name: str, caller_group: int):
        """
        Create a new spell.
        
        Args:
            spell_name: Name for identification
            caller_group: Group that triggers this spell
        """
        self.spell_name: str = spell_name
        self.caller_group: int = caller_group
        self.components: list[ComponentProtocol] = []
        all_spells.append(self)
    
    def add_component(self, component: ComponentProtocol) -> 'Spell':
        """Add a component to this spell. Returns self for chaining."""
        self.components.append(component)
        return self


# ============================================================================
# IN-LEVEL GROUP ASSIGNMENTS
# (i.e. real objects like bullets, guidercircle, emitters)
# ============================================================================

class GuiderCircle:
    """
    Circle of 360 groups for angle-based aiming.
    Groups are arranged 1-360 degrees for precise bullet direction.
    """
    
    def __init__(self, all_group: int, center: int, pointer: int):
        """Create a guider circle."""
        self.all: int = all_group
        self.center: int = center
        self.pointer: int = pointer
        self.groups: dict[int, int] = {}
        
        # Populate groups[1..360] = pointer + (i-1)
        for i in range(1, 361):
            self.groups[i] = self.pointer + (i - 1)

circle1 = GuiderCircle(all_group=5461, center=5461, pointer=5101)

class BulletPool:
    """
    Bullet pool with group range and cycler for sequential allocation.
    Returns (bullet_group, collision_group) pairs.
    """
    
    def __init__(self, min_group: int, max_group: int):
        self.min_group: int = min_group
        self.max_group: int = max_group
        self._current: int = min_group - 1
    
    def next(self) -> tuple[int, int]:
        """
        Get the next bullet / collision group in the cycle.
        
        Returns: Tuple of (bullet_group, collision_group)
        """
        self._current += 1
        if self._current > self.max_group:
            self._current = self.min_group
        
        bullet = self._current
        collision = self.max_group + bullet
        return bullet, collision


bullet1 = BulletPool(501, 1000)
bullet2 = BulletPool(1501, 2200)
bullet3 = BulletPool(2901, 3600)
bullet4 = BulletPool(4301, 4700)


def get_all_components() -> list[ComponentProtocol]:
    """Return list of all registered components."""
    return all_components

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

def _spread_triggers(triggers: list[Trigger], component: ComponentProtocol) -> None:
    """
    Spread triggers across TRIGGER_AREA based on spawn order requirement.
    Modifies trigger X/Y positions in-place.
    
    Args:
        triggers: List of trigger dicts to spread
        component: Component object with requireSpawnOrder attribute
    """
    if len(triggers) < 1:
        raise ValueError(f"No triggers in component {component.componentName}")
    
    ppt = enum.Properties
    
    # Single trigger - random position
    if len(triggers) == 1:
        triggers[0][ppt.X] = random.randint(TRIGGER_AREA["min_x"], TRIGGER_AREA["max_x"])
        triggers[0][ppt.Y] = random.randint(TRIGGER_AREA["min_y"], TRIGGER_AREA["max_y"])
        return
    
    # Check if all triggers have same X (time-based pattern)
    same_x = all(t[ppt.X] == triggers[0][ppt.X] for t in triggers)
    
    if same_x and not component.requireSpawnOrder:
        # Loose squares - random positions (simultaneous spawn)
        for trigger in triggers:
            trigger[ppt.X] = random.randint(TRIGGER_AREA["min_x"] // 2, TRIGGER_AREA["max_x"] // 2) * 2
    
    elif component.requireSpawnOrder:
        # Rigid chain - maintain exact spacing (ordered spawn)
        min_x = min(float(t[ppt.X]) for t in triggers)
        max_x = max(float(t[ppt.X]) for t in triggers)
        chain_width = max_x - min_x
        
        # Check if chain fits in trigger area
        if chain_width > (TRIGGER_AREA["max_x"] - TRIGGER_AREA["min_x"]):
            raise ValueError(f"Rigid chain too wide ({chain_width}) to fit in trigger area for {component.componentName}")
        
        # Shift entire chain to random position
        shift = float(random.randint(TRIGGER_AREA["min_x"], int(TRIGGER_AREA["max_x"] - chain_width)) - min_x)
        for trigger in triggers:
            trigger[ppt.X] = float(trigger[ppt.X]) + shift
    
    else:
        # Elastic chain - can stretch beyond area (no spawn order requirement)
        start_x = TRIGGER_AREA["min_x"]
        for i, trigger in enumerate(triggers):
            if i == 0:
                trigger[ppt.X] = start_x
            else:
                spacing = random.randint(1, 10)
                trigger[ppt.X] = float(triggers[i - 1][ppt.X]) + spacing
    
    # Set random Y for all triggers
    for trigger in triggers:
        trigger[ppt.Y] = random.randint(TRIGGER_AREA["min_y"], TRIGGER_AREA["max_y"])


def _generate_statistics(object_budget: int = 200000) -> dict[str, Any]:
    """
    Generate statistics about trigger usage and budget.
    """
    total_triggers = sum(len(c.triggers) for c in all_components)
    
    spell_stats = {}
    component_stats = {}
    
    component_usage: dict[ComponentProtocol, int] = {}
    for spell in all_spells:
        for comp in spell.components:
            component_usage[comp] = component_usage.get(comp, 0) + 1
    
    shared_components = {comp for comp, count in component_usage.items() if count > 1}
    
    for spell in all_spells:
        spell_trigger_count = 0
        for comp in spell.components:
            if comp not in shared_components:
                spell_trigger_count += len(comp.triggers)
        spell_stats[spell.spell_name] = spell_trigger_count
    
    shared_trigger_count = sum(len(comp.triggers) for comp in shared_components)
    
    for comp in all_components:
        component_stats[comp.componentName] = len(comp.triggers)
    
    usage_percent = (total_triggers / object_budget) * 100 if total_triggers > 0 else 0
    remaining_budget = object_budget - total_triggers
    
    return {
        "spell_stats": spell_stats,
        "component_stats": component_stats,
        "shared_trigger_count": shared_trigger_count,
        "budget": {
            "total_triggers": total_triggers,
            "object_budget": object_budget,
            "usage_percent": usage_percent,
            "remaining_budget": remaining_budget
        }
    }


def _print_budget_analysis(stats: dict[str, Any]) -> None:
    """Print formatted budget analysis to console."""
    budget = stats["budget"]
    print("\n=== BUDGET ANALYSIS ===")
    print(f"Total triggers: {budget['total_triggers']} ({budget['usage_percent']:.3f}%)")
    print(f"Remaining budget: {budget['remaining_budget']} triggers")
    
    spell_stats = stats.get("spell_stats", {})
    if spell_stats:
        print("\nSpells:")
        for spell_name, count in spell_stats.items():
            print(f"  {spell_name}: {count} triggers")
    
    component_stats = stats.get("component_stats", {})
    if component_stats:
        print("\nComponents:")
        for component_name, count in component_stats.items():
            print(f"  {component_name}: {count} triggers")
    
    shared_count = stats.get("shared_trigger_count", 0)
    if shared_count > 0:
        print(f"\nShared components: {shared_count} triggers")


def save_all(filename: str = "triggers.json", object_budget: int = 200000) -> None:
    """
    Export all component triggers to JSON file for main.js processing.
    Handles spreading, sorting, validation, and statistics.
    """
    output: dict[str, list[Trigger]] = {"triggers": []}
    
    ppt = enum.Properties # shorthand
    
    for comp in all_components:
        if len(comp.triggers) == 0:
            warn(f"Component {comp.componentName} has no triggers", stacklevel=2)
            continue
        
        sorted_triggers: list[Trigger] = comp.triggers.copy()
        _spread_triggers(sorted_triggers, comp)
        sorted_triggers.sort(key=lambda t: float(t[ppt.X]))
        
        prev_x = -10000
        for trigger in sorted_triggers:
            if trigger[ppt.GROUPS] == 9999:
                raise RuntimeError(
                    f"CRITICAL ERROR: Reserved group 9999 detected in {comp.componentName}"
                )

            curr_x: float = float(trigger[ppt.X])  
            if 0 < curr_x - prev_x < 1:
                raise RuntimeError(
                    "CRITICAL ERROR: X position within 1 unit of previous trigger " +
                    f"in {comp.componentName} - spawn order not preserved"
                )
            
            prev_x = curr_x
            output["triggers"].append(trigger)
    
    stats = _generate_statistics(object_budget)
    _print_budget_analysis(stats)
    
    with open(filename, "w") as file:
        json.dump(output, file)
    
    elapsed = time.time() - _start_time
    print(f"\nSaved to {filename} successfully!")
    print(f"Total execution time: {elapsed:.3f} seconds")
