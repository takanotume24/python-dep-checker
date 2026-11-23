# syntax=docker/dockerfile:1.7

FROM docker.io/nixos/nix:2.36.0 AS build

RUN printf 'experimental-features = nix-command flakes\nsandbox = false\n' >> /etc/nix/nix.conf

WORKDIR /src
COPY . .

RUN set -eux; \
    NIXPKGS="$(nix eval --raw --impure --expr '(builtins.getFlake (toString /src)).inputs.nixpkgs.outPath')"; \
    nix profile add "$NIXPKGS#gnused" "$NIXPKGS#glibc.bin"

RUN set -eux; \
    OUT="$(nix build --no-link --print-out-paths .#default)"; \
    BIN="$OUT/bin/python-dep-checker"; \
    "$BIN" --help >/dev/null; \
    mkdir -p /runtime/nix/store /runtime/usr/local/bin; \
    install -m 0755 "$BIN" /runtime/usr/local/bin/python-dep-checker; \
    ldd "$BIN" > /tmp/ldd.txt; \
    if grep -q 'not found' /tmp/ldd.txt; then \
      grep . /tmp/ldd.txt >&2; \
      exit 1; \
    fi; \
    grep -o '/nix/store/[^ ]*' /tmp/ldd.txt \
      | sed 's#\(/nix/store/[^/]*\)/.*#\1#' \
      | sort -u > /tmp/packages.txt; \
    test -s /tmp/packages.txt; \
    while read -r package; do cp -a "$package" /runtime/nix/store/; done < /tmp/packages.txt

FROM docker.io/library/debian:bookworm-slim

COPY --from=build /runtime/ /
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/python-dep-checker"]
