{
  description = "Basic project with pre-commit check";

  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.pre-commit-hooks = {
    url = "github:cachix/pre-commit-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.emacs-overlay = {
    url = "github:nix-community/emacs-overlay";
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
    , pre-commit-hooks
    , gitignore
    , emacs-overlay
    , emacs-ci
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            emacs-overlay.overlay
          ];
        };

        inherit (gitignore.lib) gitignoreSource;

        makeEmacs = version: emacs-ci.packages.${system}.${version};

        emacs = makeEmacs "emacs-27-2";
      in
      rec {
        packages = flake-utils.lib.flattenTree (
          builtins.mapAttrs (name: emacs:
            let
              epkgs = (pkgs.emacsPackagesFor emacs);
            in
              epkgs.magit.overrideAttrs (pkg: {
                buildInputs = pkg.buildInputs ++ [epkgs.libgit];
              })
          ) emacs-ci.packages.${system}
        );
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = gitignoreSource ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              nix-linter.enable = true;
            };
          };
        };
        devShell = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };
      });
}
