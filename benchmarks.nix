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
              ref = "master";
            };

        inherit benchmark;
      };
  }
