{
  description = "Defect process";

  inputs = {
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    haskellNix.url = "github:input-output-hk/haskell.nix";
  };

  outputs = { self, nixpkgs, flake-utils, haskellNix }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      name = "defect-process";
      executable-name = "defect-process";
      overlays = [ haskellNix.overlay
        (final: prev: {
            # This overlay adds our project to pkgs
            project =
              final.haskell-nix.cabalProject' {
                inherit name;
                src = ./.;
                compiler-nix-name = "ghc865";
              };
            })
          # llvm-overlay
      ];
      pkgs = import nixpkgs { inherit system overlays; };
      flake = pkgs.project.flake {};
      executable = "${name}:exe:${executable-name}";
      app = flake-utils.lib.mkApp {
        inherit name;
        drv = self.packages.${system}.${executable};
      };
    in flake // {
      # Built by `nix build .`
      defaultPackage = self.packages.${system}.${executable};

      # `nix run`
      apps.${executable} = app;
      defaultApp = app;

      # This is used by `nix develop .` to open a shell for use with
      # `cabal`, `hlint` and `haskell-language-server`
      devShell = pkgs.project.shellFor {
        tools = {
          cabal = "latest";
          hlint = "latest";
          haskell-language-server = "latest";
        };
      };
    }
  );
}
