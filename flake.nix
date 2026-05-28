{
  description = "Python project with pyproject.toml + nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        python = pkgs.python313;

        venvDir = ".venv";
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python313
            uv

            zlib
            verilator
            surfer
          ];

          shellHook = ''
            if [ ! -d .venv ]; then
              uv venv
            fi
            source .venv/bin/activate
          '';
        };
      }
    );
}
