{
  description = "Kong plugin development environment";

  inputs = {
    utils.url = "github:numtide/flake-utils";

    pongo = {
      type = "github";
      owner = "Kong";
      repo = "kong-pongo";
      ref = "2.6.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, pongo }:
    utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = utils.lib.flattenTree {
          deck = pkgs.buildGoModule rec {
            pname = "deck";
            version = "1.19.1";

            src = pkgs.fetchFromGitHub {
              owner = "Kong";
              repo = pname;
              rev = "v${version}";
              sha256 = "sha256-ao3SGtHwDH+1zTYAzeN37cRNLjCaSFULkXOxLTKTvxc=";
            };

            vendorSha256 =
              "sha256-xFynhV1z3+8K613pFxoVxxQeG1N+rV8/gzkpy9MPF/0=";

            excludedPackages = [ ];

            ldflags = [ "-s" "-w" "-X main.version=v${version}" ];
          };

          pongo = pkgs.writeShellApplication {
            name = "pongo";
            text = ''
              ${pongo.outPath}/pongo.sh "$@"
            '';
          };
        };

        # defines a development environment with pongo available
        # preferably use direnv to activate
        devShell = pkgs.mkShell {
          buildInputs = with pkgs;
            [ cassowary curl docker-compose fx jq pgcli ]
            ++ [ packages.deck packages.pongo ] ++ (with pkgs.luaPackages; [
              luarocks
              luacov
              luacheck
              luaformatter
            ]);
        };
      });
}
