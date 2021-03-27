{ gitignoreSrc = builtins.fetchGit
    { url = "https://github.com/hercules-ci/gitignore.nix.git";
      rev = "211907489e9f198594c0eb0ca9256a1949c9d412";
    };

  nixpkgs =
    builtins.fetchGit
      { url = "https://github.com/NixOS/nixpkgs.git";
        rev = "04ac9dcd311956d1756d77f4baf9258392ee7bdd";
      };
}
