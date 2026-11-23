{
  description = "Enumerate Python files imported by a specific Jupyter notebook";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      eachSystem = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      mkProject = pkgs:
        let
          hpkgs = pkgs.haskell.packages.ghc910;
        in
        {
          inherit pkgs hpkgs;
          project = hpkgs.callCabal2nix "python-dep-checker" ./. { };
        };
    in
    {
      packages = eachSystem (pkgs:
        let p = mkProject pkgs;
        in {
          default = p.project;
        });

      devShells = eachSystem (pkgs:
        let p = mkProject pkgs;
        in {
          default = pkgs.mkShell {
            packages = [
              p.hpkgs.ghc
              p.hpkgs.cabal-install
              p.hpkgs.haskell-language-server
              p.hpkgs.ormolu
              p.hpkgs.hlint
              p.pkgs.git
              p.pkgs.jq
            ];

            shellHook = ''
              echo "python-dep-checker nix dev shell"
              echo "- run: cabal update"
              echo "- run: cabal build all"
              echo "- run: cabal test"
            '';
          };
        });

      formatter = eachSystem (pkgs: pkgs.nixpkgs-fmt);
    };
}
