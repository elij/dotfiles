{
  description = "My global macOS packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-24.11";
    mac-app-util.url = "github:hraban/mac-app-util";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    lean4-nix.url = "github:lenianiva/lean4-nix";
  };

  outputs = { self, nixpkgs, nixpkgs-old, mac-app-util, emacs-overlay, lean4-nix }:
  let
    system = "aarch64-darwin";
      
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (import emacs-overlay)
        lean4-nix.tags."v4.16.0".lean-bin
      ];
    };

    pkgsOld = import nixpkgs-old { inherit system; };

    fixedLean = pkgs.lean.lean-all.overrideAttrs (_: {
      dontFixup = true;
    });

    fixedEmacs = pkgs.emacs-git.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        (pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/community/patches/frame-transparency/emacs-31.patch";
          hash = "sha256-qfW8NLwRpCc3v9vbYyXLMDsTscfpAuFUCwk0uzSXdsw=";
        })
      ];

      preConfigure = (oldAttrs.preConfigure or "") + ''
        export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -std=gnu99"
      '';

      buildInputs = (builtins.filter (x: (x.pname or "") != "tree-sitter") (oldAttrs.buildInputs or [ ]))
      ++ [ pkgsOld.tree-sitter ];

      configureFlags = (oldAttrs.configureFlags or [ ]) ++ [ 
        "--with-tree-sitter" 
        "--with-modules"
      ];

      postPatch = (oldAttrs.postPatch or "") + ''
        sed -i 's|${pkgs.tree-sitter}/lib/libtree-sitter.dylib|${pkgsOld.tree-sitter}/lib/libtree-sitter.dylib|g' src/treesit.c
        sed -i 's|"libtree-sitter.dylib"|"${pkgsOld.tree-sitter}/lib/libtree-sitter.dylib"|g' src/treesit.c
      '';
    });

  in
  {
    packages.${system}.default = pkgs.buildEnv {
      name = "user-packages";
      paths = with pkgs; [
        fixedEmacs
        fixedLean
        git
        gnupg
        deno
        pandoc
        (lib.lowPrio jdk8)
        jdk25_headless
        ghostscript
        jq
        llama-cpp
        protobuf
        tcl
        asciinema
        ascii-image-converter
        nerd-fonts.symbols-only
        jd-diff-patch
        meld
        ghidra
        iosevka-bin
        openssl
        ffmpeg
        tree-sitter
        hunspellDicts.en_GB-ise
        hunspell
        android-tools
        tcptraceroute
        zig
      ];

      pathsToLink = [ "/bin" "/share" "/Applications" ];
    };
  };
}