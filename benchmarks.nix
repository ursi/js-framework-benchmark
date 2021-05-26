let
  urls =
    { shpadoinkle = "https://gitlab.com/fresheyeball/Shpadoinkle";
      benchmark = "https://gitlab.com/athan.clark/shpaboinchkle";
    };

  benchmark =
    builtins.fetchGit
      { url = urls.benchmark;
        rev = "97b4aab4ec129dcbef2ebd36a1cf6f0a20998751";
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
              rev = "6139267ece9bdbfab437342cdad588061f3a3694";
            };

        inherit benchmark;
      };
  }
