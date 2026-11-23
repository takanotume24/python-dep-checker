"""Core helpers for the demo package."""

from . import sibling
from demo_pkg.utils.helpers import shout


def compute(value: int) -> str:
    return shout(str(value + sibling.OFFSET))
