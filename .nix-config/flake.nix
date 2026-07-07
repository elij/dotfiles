{
  description = "My global macOS packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-24.11";
    mac-app-util.url = "github:hraban/mac-app-util";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { self, nixpkgs, nixpkgs-old, mac-app-util, emacs-overlay }:
  let
    system = "aarch64-darwin";
      
    # The overlay is no longer needed for the standard build
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ (import emacs-overlay) ];
    };

    pkgsOld = import nixpkgs-old { inherit system; };

    # Target Emacs 31 via the overlay
    fixedEmacs = pkgs.emacs-git.overrideAttrs (oldAttrs: {
      
      # Apply the Emacs 31 transparency patch
      patches = (oldAttrs.patches or [ ]) ++ [
        (pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/community/patches/frame-transparency/emacs-31.patch";
          hash = "sha256-qfW8NLwRpCc3v9vbYyXLMDsTscfpAuFUCwk0uzSXdsw="; # Nix will provide the expected hash on the first build failure
        })
      ];

      # Append the C standard safely before configuration steps execute
      preConfigure = (oldAttrs.preConfigure or "") + ''
        export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -std=gnu99"
      '';

      # Ensure tree-sitter is available as a build dependency
      buildInputs = (builtins.filter (x: (x.pname or "") != "tree-sitter") (oldAttrs.buildInputs or [ ]))
      ++ [ pkgsOld.tree-sitter ];

      # Configure Emacs to use the tree-sitter library and support modules
      configureFlags = (oldAttrs.configureFlags or [ ]) ++ [ 
        "--with-tree-sitter" 
        "--with-modules"
      ];

      # Point the dynamic linker to the older tree-sitter library
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
        git
        gnupg
        deno
        pandoc
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
      ];

      pathsToLink = [ "/bin" "/share" "/Applications" ];

    };
  };
}
