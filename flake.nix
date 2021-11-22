{
  description = "A Git porcelain inside Emacs";

  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.emacs-ci = {
    url = "github:akirak/nix-emacs-ci/add-flake";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , emacs-ci
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      {
        packages = flake-utils.lib.flattenTree (
          builtins.mapAttrs
            (name: emacs:
              let
                epkgs = (nixpkgs.legacyPackages.${system}.emacsPackagesFor emacs);
              in
              epkgs.magit.overrideAttrs (pkg: {
                buildInputs = pkg.buildInputs ++ [ epkgs.libgit ];
              })
            )
            emacs-ci.packages.${system}
        );
      });
}
