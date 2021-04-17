let
  f = builtins.fetchGit;

  gitignoreSrc =
   f { url = "https://github.com/hercules-ci/gitignore.nix.git";
       rev = "211907489e9f198594c0eb0ca9256a1949c9d412";
     };

  make-shell =
    f { url = "https://github.com/ursi/nix-make-shell.git";
        rev = "908f54ca8a3c5e45a2689aac27ba75aa5a02adaa";
      };

  nixpkgs =
    f { url = "https://github.com/NixOS/nixpkgs.git";
        rev = "04ac9dcd311956d1756d77f4baf9258392ee7bdd";
      };

  lib = pkgs.lib;
  pkgs = import nixpkgs { config = { allowUnfree = true; }; };
  system = builtins.currentSystem;
in
{ inherit (import gitignoreSrc { inherit lib; }) gitignoreSource;
  make-shell = import make-shell { inherit pkgs system; };
  inherit pkgs;
}
