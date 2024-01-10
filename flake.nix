{
  description = "Kong plugin development environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";

    ikselven-packages.url = "git+https://codeberg.org/ikselven/nix-packages?ref=main";
    ikselven-packages.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    utils,
    ikselven-packages,
    ...
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs-ikselven = ikselven-packages.packages.${system};
      pkgs = import nixpkgs {
        inherit system;

        overlays = [
          (final: prev: {
            deck = pkgs-ikselven.deck;
            kong-pongo = pkgs-ikselven.kong-pongo;
          })
        ];
      };
    in rec {
      formatter = pkgs.alejandra;

      # defines a development environment with pongo available
      # preferably use direnv to activate
      devShell = pkgs.mkShell {
        buildInputs = with pkgs;
          [
            cassowary
            curl
            deck
            docker-compose
            fx
            jq
            kong-pongo
            pgcli
          ]
          ++ (with pkgs.luaPackages; [
            luarocks
            luacov
            luacheck
            luaformatter
          ]);
      };
    });
}
