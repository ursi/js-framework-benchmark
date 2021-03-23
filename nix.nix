(import
  (builtins.fetchGit
    { url = "https://github.com/NixOS/nixpkgs";
      ref = "nixpkgs-unstable";
      rev = "f5f6dc053b1a0eca03c853dad710f3de070df24e";
    }
  )
  {}
).nix
