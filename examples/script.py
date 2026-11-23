"""Plain Python entrypoint for python-dep-checker."""

import demo_pkg.core
from demo_pkg.utils import helpers


def main() -> None:
    print(demo_pkg.core.compute(41))
    print(helpers.shout("done"))


if __name__ == "__main__":
    main()
