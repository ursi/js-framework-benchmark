{ inputs.js-framework-benchmark.url = "github:ursi/js-framework-benchmark";

  outputs =
    { self, nixpkgs, js-framework-benchmark }:
      let
        system = "x86_64-linux";

        pkgs = import nixpkgs
          { inherit system;
            config = { allowUnfree = true; };
          };

        inherit (nixpkgs) lib;

        nodeModules =
          let
            # use an absolute path from the 'js-framework-benchmark' dir
            getNodeModules = path:
              # the flake is used instead of the local directory so local changes don't require a full rebuild
              (import (js-framework-benchmark + path) { inherit pkgs system; }).shell.nodeDependencies
                + /lib/node_modules;

            unpatched =
              lib.mapAttrs
                (_: path: getNodeModules path)
                { main = /.;
                  webdriver = /webdriver-ts;
                  webdriverResults = /webdriver-ts-results;
                };
          in
            unpatched
              // { webdriver = with pkgs;
                    runCommand "node_modules" {}
                      ''
                      mkdir $out
                      cd $out
                      cp -r ${unpatched.webdriver}/. .
                      chmod -R +w .
                      cd chromedriver/lib
                      mkdir chromedriver
                      ln -s ${chromedriver}/bin/chromedriver chromedriver
                      '';
                 };
      in with pkgs;
        { devShell.${system} =
            mkShell
              { buildInputs =
                  [ google-chrome
                    nodejs
                    nodePackages.node2nix
                  ];

                shellHook =
                  let
                    help =
                      lib.escapeShellArg
                        ''
                        run 'npm start' to start the server required to run the benchmakrs and view the results

                        Commands:
                          bench ([non-]keyed/<framework>)+     benchmark the given framework(s)
                          results                              build the results table
                      '';
                  in
                    ''
                    rm -fr node_modules && ln -s ${nodeModules.main} node_modules

                    (
                      cd webdriver-ts
                      rm -fr node_modules
                      # for some reason the typescript won't compile if it's a symlink
                      cp -r ${nodeModules.webdriver} node_modules
                      chmod -R +w node_modules
                      npm run build-prod
                    )

                    (
                      cd webdriver-ts-results
                      rm -fr node_modules && ln -s ${nodeModules.webdriverResults} node_modules
                    )

                    echo ${help}
                    alias node2nix="node2nix -d -l package-lock.json"

                    bench () (
                      cd webdriver-ts
                      npm run bench $@
                    )

                    results () (
                      cd webdriver-ts
                      npm run results
                      echo -e "\nview table: http://localhost:8080/webdriver-ts-results/table.html"
                    )
                    '';
              };
        };
}
