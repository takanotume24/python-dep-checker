# syntax=docker/dockerfile:1.7

FROM nixos/nix:2.36.0 AS build

RUN printf 'experimental-features = nix-command flakes\nsandbox = false\n' >> /etc/nix/nix.conf

WORKDIR /src
COPY . .

RUN set -eux; \
    OUT="$(nix build --no-link --print-out-paths .#default)"; \
    BIN="$OUT/bin/python-dep-checker"; \
    mkdir -p /runtime/nix/store /runtime/usr/local/bin; \
    install -m 0755 "$BIN" /runtime/usr/local/bin/python-dep-checker; \
    if ldd "$BIN" | grep -q 'not found'; then \
      echo "missing shared libraries for $BIN" >&2; \
      ldd "$BIN" >&2; \
      exit 1; \
    fi; \
    ldd "$BIN" \
      | grep -o '/nix/store/[^ ]*' \
      | sed 's#\(/nix/store/[^/]*\)/.*#\1#' \
      | sort -u \
      | while read -r package; do cp -a "$package" /runtime/nix/store/; done

FROM debian:bookworm-slim

COPY --from=build /runtime/ /
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/python-dep-checker"]
