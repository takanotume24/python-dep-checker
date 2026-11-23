"""Helper functions used by the demo package."""

from __future__ import annotations

import math


def shout(text: str) -> str:
    return f"{text.upper()} {math.pi:.2f}"
