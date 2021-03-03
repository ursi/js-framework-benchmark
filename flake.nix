{
# inputs =
#     { shpaboinchkle =
#         { url = "gitlab:fresheyeball/shpaboinchkle/mostly-miso";
#           flake = false;
#         };

#       shpadoinkle =
#         { url = "gitlab:fresheyeball/Shapadoinkle/hell-scape";
#           flake = false;
#         };
#     };

  outputs =
    { self, nixpkgs, utils}:# , shpaboinchkle, shpadoinkle }:
      let
        system = "x86_64-linux";

        pkgs = import nixpkgs
          { inherit system;
            config = { allowUnfree = true; };
          };
      in
        { devShell.${system} = with pkgs;
            mkShell
              { buildInputs =
                  [ chromedriver
                    google-chrome
                    jre8
                    nodejs
                    nodePackages.node2nix
                  ];

                shellHook =
                  ''
                  echo 'after running `npm install` inside `webdriver-ts`, run `patch-chromedriver` from the same directory'

                  alias node2nix="node2nix -d -l package-lock.json"

                  patch-chromedriver () {
                    mkdir node_modules/chromedriver/lib/chromedriver \
                    && ln -fs $(which chromedriver) node_modules/chromedriver/lib/chromedriver \
                    && echo '`chromedriver` patched successfully. You can now run `npm run bench ...`'
                  }
                  '';
              };
        };
}
