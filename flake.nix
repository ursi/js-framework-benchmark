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

        # use an absolute path from the js-framework-benchmarks dir
        getNodeModules = path:
          # the flake is used instead of the local directory so local changes don't make it have to rebuild
          (import (js-framework-benchmark + path) { inherit pkgs system; }).shell.nodeDependencies
            + /lib/node_modules;

        nodeModules =
          lib.mapAttrs
            (_: path: getNodeModules path)
            { main = /.;
              webdriver = /webdriver-ts;
              webdriverResults = /webdriver-ts-results;
            };

      in with pkgs;
        { devShell.${system} =
            mkShell
              { buildInputs =
                  [ chromedriver
                    google-chrome
                    jre8
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
                      rm -fr node_modules && cp -r ${nodeModules.webdriver} node_modules
                      chmod -R +w node_modules
                      npm run build-prod
                      cd node_modules/chromedriver/lib
                      mkdir chromedriver
                      ln -s ${chromedriver}/bin/chromedriver chromedriver
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
