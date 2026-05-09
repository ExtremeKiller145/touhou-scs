"""
Touhou SCS - Utilities Module

Helper functions for component building and validation.
"""

from __future__ import annotations

import math
from typing import Any, Callable, TYPE_CHECKING
import warnings
import functools

if TYPE_CHECKING:
    from gmdbuilder import Level

from touhou_scs import enums as enum
from touhou_scs.types import ComponentProtocol


class CallTracked:
    def __init__(self, func: Callable[..., Any]):
        self.__func = func
        self.has_been_called = False
        functools.update_wrapper(self, func)

    def __call__(self, *args: Any, **kwargs: Any):
        try:
            return self.__func(*args, **kwargs)
        finally:
            self.has_been_called = True

def calltracker(func: Callable[..., Any]) -> CallTracked:
    """Decorator that assigns func.has_been_called. Does not track call count."""
    return CallTracked(func)

def warn(message: str, *, stacklevel: int = 3):
    warnings.warn("\u001B[33m\n" + message + "\u001B[0m", stacklevel=stacklevel)

def time_to_dist(time: float) -> float:
    """Based on plr move speed of 311.58 studs/s"""
    return 311.58 * time

def round_to_n_sig_figs(x: float | int, n: int) -> float:
    """Round to n significant figures (GD uses 6)"""
    return 0 if x == 0 else round(x, -int(math.floor(math.log10(abs(x)))) + (n - 1))


class _GroupAllocatorProxy:
    """
    Proxy for allocating unique group IDs via level.new.group().

    Before init_level() is called, any call raises a clear RuntimeError.
    After init_level() is called, every call delegates to level.new.group(),
    skipping any groups that fall within a registered reserved range.
    """

    def __init__(self) -> None:
        self._level: Level | None = None
        self.count = 0
        self._reserved_ranges: list[tuple[int, int]] = []  # list of (min, max) inclusive

    def reserve_range(self, min_group: int, max_group: int) -> None:
        """Register a group range that unknown_g() must never allocate into."""
        self._reserved_ranges.append((min_group, max_group))

    def _is_reserved(self, g: int) -> bool:
        return any(lo <= g <= hi for lo, hi in self._reserved_ranges)

    def init(self, level: Level) -> None:
        if self._level is not None:
            raise RuntimeError("init_level() has already been called.")
        self._level = level

    def __call__(self) -> int:
        if self._level is None:
            raise RuntimeError(
                "unknown_g() called before init_level(). "
                "Call init_level(level) in main.py immediately after "
                "Level.from_file() / Level.from_live_editor(), before "
                "any other touhou_scs imports."
            )
        g = int(self._level.new.group())
        while self._is_reserved(g):
            g = int(self._level.new.group())
        self.count += 1
        return g


unknown_g = _GroupAllocatorProxy()
"""Allocate the next free group ID from the loaded level. Requires init_level() first."""


def init_level(level: Level) -> None:
    """
    Bind the loaded Level instance to the group allocator.
    Must be called once in main.py, immediately after Level.from_file() or
    Level.from_live_editor(), before any other touhou_scs imports.
    """
    unknown_g.init(level)


def group(group_id: int) -> int: """Semantic Wrapper"""; return group_id # noqa

@functools.lru_cache(maxsize=4096)
def translate_remap_string(remap_string: str) -> tuple[dict[int, int], str]:
    """Returns (dict[source] = target, clean_remap_string)"""

    parts = remap_string.split(".")
    parts_len = len(parts)

    if parts_len == 0:
        raise ValueError("Remap string is empty")
    if parts_len % 2 != 0:
        raise ValueError(f"Remap string must contain an even number of parts:\n{remap_string}")

    pairs: dict[int, int] = {}
    clean_parts: list[str] = []
    redundant_mappings: list[str] = []
    for i in range(0, parts_len, 2):
        source_str = parts[i]
        target_str = parts[i + 1]
        source = int(source_str)
        target = int(target_str)

        if source in pairs:
            raise ValueError(f"Duplicate source '{source}' in remap string - cannot remap one group to multiple targets")
        pairs[source] = target

        if source != target:
            clean_parts.append(source_str)
            clean_parts.append(target_str)
        else:
            redundant_mappings.append(f"{source}->{target}")

    clean_string = ".".join(clean_parts)

    if clean_string != remap_string:
        warn(f"Remap string had redundant identity mappings: {', '.join(redundant_mappings)}\nFull string:\n{remap_string}")
    if len(clean_string) == 0:
        raise ValueError(f"Remap string is empty after cleaning redundant mappings: \n {remap_string}")

    return pairs, clean_string


class Remap:
    """Remap string builder class with chainable API."""
    def __init__(self): self.pairs: dict[int,int] = {}

    def pair(self, source: int, target: int):
        self.pairs[source] = target
        return self

    def build(self) -> str:
        parts: list[str] = []
        for source, target in self.pairs.items():
            parts.append(f"{source}.{target}")
        return ".".join(parts)


def create_number_cycler(min_val: int, max_val: int) -> Callable[[], int]:
    if min_val > max_val: 
        raise ValueError("create_number_cycler: min cannot be greater than max")

    current = min_val - 1
    def cycler() -> int:
        nonlocal current
        current += 1
        if current > max_val: current = min_val
        return current
    return cycler


def enforce_component_targets(fn_name: str, comp: ComponentProtocol,*,
    requires: set[int] | None = None, excludes: set[int] | None = None):
    """Validate that component targets (or doesn't target) specific groups"""
    if comp.requireSpawnOrder is not True:
        raise ValueError(f"{fn_name}: component must require spawn order")

    requires = requires or set()
    excludes = excludes or set()

    found_targets: set[int] = set()
    for trigger in comp.triggers:
        for field in enum.TARGET_FIELDS:
            target = trigger.get(field)
            if target is not None and isinstance(target, int):
                found_targets.add(target)

    missing = requires - found_targets
    if missing:
        missing_names = [f"{g}" for g in missing]
        raise ValueError(
            f"{fn_name}: component must target {', '.join(missing_names)}"
        )

    forbidden = found_targets & excludes
    if forbidden:
        forbidden_names = [f"{g}" for g in forbidden]
        raise ValueError(
            f"{fn_name}: component must not target {', '.join(forbidden_names)}"
        )
