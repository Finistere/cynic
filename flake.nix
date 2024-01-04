{
  # Nix: https://nixos.org/download.html
  # How to activate flakes: https://nixos.wiki/wiki/Flakes
  # For seamless integration, consider using:
  # - direnv: https://github.com/direnv/direnv
  # - nix-direnv: https://github.com/nix-community/nix-direnv
  #
  # # .envrc
  # use flake
  # dotenv .env
  #
  description = "Grafbase CLI development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }: let
    inherit (nixpkgs.lib) optional concatStringsSep;
    systems = flake-utils.lib.system;
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      aarch64DarwinExternalCargoCrates = concatStringsSep " " ["cargo-instruments@0.4.8"];

      defaultShellConf = {
        nativeBuildInputs = with pkgs;
          [
            # Testing
            cargo-insta
            cargo-nextest


            # Native SSL
            openssl
            pkg-config

            # Rust
            rustup
            libiconv

          ]
          ++ optional (system == systems.aarch64-darwin) [
            cargo-binstall
            darwin.apple_sdk.frameworks.CoreFoundation
            darwin.apple_sdk.frameworks.CoreServices
            darwin.apple_sdk.frameworks.Security
            darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        shellHook = ''
          project_root="$(git rev-parse --show-toplevel 2>/dev/null || jj workspace root 2>/dev/null)"
          export CARGO_INSTALL_ROOT="$project_root/.cargo";
          export PATH="$CARGO_INSTALL_ROOT/bin:$project_root/node_modules/.bin:$PATH";
          if [[ "${system}" == "aarch64-darwin" ]]; then
            cargo binstall --no-confirm --no-symlinks --quiet ${aarch64DarwinExternalCargoCrates}
          fi
        '';
      };
    in {
      devShells.default = pkgs.mkShell defaultShellConf;
    });
}
