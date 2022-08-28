{
  description = "Waymonad flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    haskell-wayland = {
      url = "github:L-as/haskell-wayland";
      flake = false;
    };
    
    hsroots = {
      url = "github:L-as/hsroots/master";
      flake = false;
    };

    waymonad-scanner = {
      url = "github:waymonad/waymonad-scanner";
      flake = false;
    };

    input = {
      url = "github:L-as/libinput";
      flake = false;
    };

    xkbcommon = {
      url = "github:L-as/haskell-xkbcommon";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils,
              haskell-wayland, hsroots, waymonad-scanner, input, xkbcommon }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        hspkgs = pkgs.haskellPackages.override {
          overrides = final: prev: {
            xkbcommon = prev.callCabal2nix "xkbcommon" xkbcommon { };
            input = (prev.callCabal2nix "libinput" input { }).overrideAttrs (old: rec {
              buildInputs = old.buildInputs ++ [ pkgs.libinput ];
            });
            waymonad-scanner = prev.callCabal2nix "waymonad-scanner" waymonad-scanner { };
            hayland =
              (pkgs.haskell.lib.dontCheck
                (prev.callCabal2nix "hayland" haskell-wayland { })).overrideAttrs (old: rec {
                  buildInputs = old.buildInputs ++ [ prev.c2hs ];
                });
            hsroots = prev.callCabal2nix "hsroots" hsroots { };
          };
        };
      in
      rec {
        packages = flake-utils.lib.flattenTree {
          waymonad = hspkgs.callCabal2nix "waymonad" ./. { };
        };
        
        defaultPackage = packages.waymonad;

        devShell = hspkgs.shellFor {
          packages = p: [ packages.waymonad p.hsroots p.hayland p.waymonad-scanner ];
          buildInputs = [ pkgs.cabal-install pkgs.haskell-language-server ];
        };
      });
}
