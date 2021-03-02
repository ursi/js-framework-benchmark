{ outputs =
    { self, nixpkgs, utils }:
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
                    nodePackages.node2nix
                    nodejs
                  ];

                shellHook =
                  ''
                  echo 'after running `npm install` inside `webdriver-ts`, run `patch-chromedriver` from the same directory'

                  patch-chromedriver () {
                    ln -fs $(which chromedriver) node_modules/chromedriver/lib/chromedriver
                    echo '`chromedriver` patched successfully. You can now run `npm run bench ...`'
                  }
                  '';
              };
        };
}
