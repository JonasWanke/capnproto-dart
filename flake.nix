{
  inputs = {
    # Dart 3.4.2: https://github.com/NixOS/nixpkgs/commit/483914124e9ec4808e97d444b280188fc59ea0b9
    nixpkgs.url =
      "github:nixos/nixpkgs?ref=483914124e9ec4808e97d444b280188fc59ea0b9";
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in { devShell = with pkgs; mkShell { buildInputs = [ dart ]; }; });
}
