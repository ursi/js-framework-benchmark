{ js-framework-benchmark = builtins.fetchGit "https://github.com/ursi/js-framework-benchmark.git";

  nixpkgs =
    builtins.fetchGit
      { url = "https://github.com/NixOS/nixpkgs.git";
        rev = "04ac9dcd311956d1756d77f4baf9258392ee7bdd";
      };
}
