{ inputs.js-framework-benchmark =
  { url = "github:ursi/js-framework-benchmark";
    flake = false;
  };

  outputs =
    { self, nixpkgs, js-framework-benchmark }:
      let
        system = "x86_64-linux";

        pkgs = import nixpkgs
          { inherit system;
            config = { allowUnfree = true; };
          };

        inherit (nixpkgs) lib;

        node-modules =
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
                  webdriver-results = /webdriver-ts-results;
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

        benchmarks = import ./benchmarks.nix;

        built-benchmarks =
          lib.mapAttrs
            (_: value:
              import value.benchmark
                { isJS = true;
                  shpadoinkle = value.shpadoinkle;
                }
            )
            benchmarks;

        add-benchmarks =
          lib.concatStrings
            (lib.mapAttrsToList
              (key: value:
                let
                  bm = pkgs.runCommand key {}
                    ''
                    mkdir -p $out/js
                    cd $out
                    cp ${benchmarks.${key}.benchmark}/package.json .
                    cp ${benchmarks.${key}.benchmark}/js/index.html js
                    cp ${value}/bin/shpaboinchkle.jsexe/all.min.js js
                    '';
                in
                  ''
                  (
                    cd frameworks/non-keyed
                    rm -fr ${key}
                    ln -s ${bm} ${key}
                  )
                  ''
              )
              built-benchmarks
            );

        webdriver-ts = with pkgs;
          runCommand "typescript"
            { buildInputs = [ nodePackages.typescript ]; }
            ''
            mkdir $out
            cp -r ${js-framework-benchmark}/webdriver-ts/src .
            cp ${js-framework-benchmark}/webdriver-ts/tsconfig.json .
            cp -r ${node-modules.webdriver} node_modules
            tsc --outDir $out
            '';
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

                        Commands (run from repo root):
                          bench ([non-]keyed/<framework>)+     benchmark the given framework(s)
                          results                              build the results table
                      '';
                  in
                    ''
                    rm -fr node_modules && ln -s ${node-modules.main} node_modules

                    (
                      cd webdriver-ts
                      rm -fr node_modules
                      cp -r ${node-modules.webdriver} node_modules
                      chmod -R +w node_modules
                      rm -fr dist
                      cp -r ${webdriver-ts} dist
                      chmod -R +w dist
                    )

                    (
                      cd webdriver-ts-results
                      rm -fr node_modules && ln -s ${node-modules.webdriver-results} node_modules
                    )

                    ${add-benchmarks}

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
