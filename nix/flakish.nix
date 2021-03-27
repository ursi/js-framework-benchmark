let
  inherit (import ./inputs.nix) gitignoreSrc nixpkgs;
  inherit (import gitignoreSrc { inherit lib; }) gitignoreSource;
  inherit (pkgs) lib;
  pkgs = import nixpkgs { config = { allowUnfree = true; }; };

  node-modules =
    let
      # use an absolute path from the 'js-framework-benchmark' dir
      getNodeModules = path:
        (import (../. + path) { inherit pkgs; }).nodeDependencies
        + /lib/node_modules;

      unpatched =
        lib.mapAttrs
          (_: path: getNodeModules path)
          { main = /node.nix;
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

  benchmarks = import ../benchmarks.nix;

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
              cp ${benchmarks.${key}.benchmark}/package-lock.json .
              cp ${benchmarks.${key}.benchmark}/js/index.html js
              cp ${value}/bin/shpaboinchkle.jsexe/all.min.js js
              '';
          in
            ''
            (
              cd frameworks/non-keyed
              \rm -fr ${key}
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
      cp -r ${../webdriver-ts/src} src
      cp ${../webdriver-ts/tsconfig.json} tsconfig.json
      cp -r ${node-modules.webdriver} node_modules
      tsc --outDir $out
      '';

  setup =
    ''
    ln -s ${node-modules.main} node_modules

    (
      cd webdriver-ts
      cp -r ${node-modules.webdriver} node_modules
      cp -r ${webdriver-ts} dist
    )

    ln -s ${node-modules.webdriver-results} webdriver-ts-results/node_modules

    ${add-benchmarks}
    '';
in with pkgs;
  { defaultPackage =
      { # array of names of other non-keyed benchmarks. check README for supported frameworks.
        other-benchmarks ? []

        # roughly the number of times to run each benchmark
      , count ? null

        # a space separated list of benchmarks to run. ex: "01 03"
      , benchmark ? null
      }:
        let
          count-str = if count != null then "--count ${toString(count)}" else "";
          benchmark-str = if benchmark != null then "--benchmark ${benchmark}" else "";
          run-benchmark = bm: "npm run bench -- non-keyed/${bm} ${count-str} ${benchmark-str} || true;";

          run-benchmarks =
            lib.concatStrings
              (lib.mapAttrsToList
                (key: _: run-benchmark key)
                benchmarks
              )
            + lib.concatStrings (builtins.map run-benchmark other-benchmarks);
        in
          stdenv.mkDerivation
            { name = "benchmark-table";
              src = gitignoreSource ../.;

              FONTCONFIG_FILE =
                makeFontsConf
                  { inherit fontconfig;
                    fontDirectories = [ "${corefonts}" ];
                  };

              buildInputs =
                [ google-chrome
                  nodejs
                  socat
                  tigervnc
                  which
                ];

              buildPhase =
                ''
                # set virtual display
                export DISPLAY=:10

                # start vnc server to host xorg in memory
                # x server (including vnc) wont create a unix socket if permissions don't line up
                # which they wont because we are inside a nix build
                # so instead we use tcp port 8999
                Xvnc :10 -listen tcp -rfbport 8999 -nolisten unix -ac -auth $PWD/auth &

                # make the folder the the unix socket where we will proxy vnc server
                mkdir -p /tmp/.X11-unix

                # socat doesn't have the same restriction as x server in regards to permissions
                # so we make the unix socket with socat, and proxy it to xvnc
                socat UNIX-LISTEN:/tmp/.X11-unix/X10 TCP:localhost:8999 &

                ${setup}

                npm start &

                (
                  cd webdriver-ts

                  ${run-benchmarks}

                  npm run results
                )
                '';

              installPhase = "mv webdriver-ts-results/table.html $out";
            };

    devShell =
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
                    remove-results                       remove all the files generated by the benchmark
                    results                              build the results table
                  '';
            in
              ''
              \rm -fr node_modules
              \rm -fr webdriver-ts/dist
              \rm -fr webdriver-ts/node_modules
              \rm -fr webdriver-ts-results/node_modules

              ${setup}

              chmod -R +w webdriver-ts/dist
              chmod -R +w webdriver-ts/node_modules

              echo ${help}

              alias node2nix="node2nix -d -l package-lock.json"
              alias build="nix build -L --impure"

              bench() (
                cd webdriver-ts
                npm run bench -- $@
              )

              remove-results() {
                \rm -fr webdriver-ts-results/src/results.ts
                \rm -fr webdriver-ts/results.json
                \rm -fr webdriver-ts-results/BoxPlotTable.*.js
                \rm -fr webdriver-ts-results/table.html
                \rm -fr table.html
              }

              results() (
                cd webdriver-ts
                npm run results
                echo -e "\nview table: http://localhost:8080/webdriver-ts-results/table.html"
              )
              '';
        };
  }
