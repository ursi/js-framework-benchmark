let
  urls =
    { shpadoinkle = "https://gitlab.com/fresheyeball/Shpadoinkle";
      benchmark = "https://gitlab.com/athan.clark/shpaboinchkle";
    };

  benchmark =
    builtins.fetchGit
      { url = urls.benchmark;
        ref = "master";
      };
in
  /* Each attribute added to this set is a different benchmark that will be built
     in the directory 'frameworks/non-keyed/<attribute>'

     each benchmark needs a 'shpadoinkle' attribute and a 'benchmark' attribute

     NOTE: To use a local repository, an absolute path must be used.
  */
  { shpadoinkle =
      { shpadoinkle =
          builtins.fetchGit
            { url = urls.shpadoinkle;
              rev = "3ed944f3be804098d1d1b51fe254747b41cbc329";
            };

        # this is running ParDiff
        benchmark =
          builtins.fetchGit
            { url = urls.benchmark;
              ref = "nix-refactor";
              rev = "3eaead58120e35eeff9e9c8c5e4c506d01bdfb66";
            };
      };
  }
