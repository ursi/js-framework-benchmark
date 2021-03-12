let
  flake-compat =
    import
      (builtins.fetchGit
        { url = "https://github.com/edolstra/flake-compat.git";
          rev = "99f1c2157fba4bfe6211a321fd0ee43199025dbf";
        }
      );
in
  (flake-compat { src = ./.; }).shellNix
