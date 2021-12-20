# ❄️ haskell.nix extra Hackage

## How to use it

I suggest you manage dependencies with [niv](https://github.com/nmattia/niv):

```shell
niv add ilyakooo0/haskell-nix-extra-hackage
```

After you import this repo and pass `pkgs`, you can pass a list of package sources that you want to overrides. You then need to add the attribute set to your `haskell.nix` config:

```nix
{ sources ? import ./nix/sources.nix
, haskellNix ? import sources.haskellNix { }
, pkgsSrc ? import haskellNix.sources.nixpkgs-2105
, pkgs ? pkgsSrc (haskellNix.nixpkgsArgs // { })
}:
let
  mkHackage = import sources.haskell-nix-extra-hackage { inherit pkgs; };

  hsPkgs = pkgs.haskell-nix.cabalProject ({
    src = ./.;
    index-state = "2021-11-22T00:00:00Z";
    compiler-nix-name = "ghc8107";

  }
  // (mkHackage [
    { src = sources.reflex-dom + "/reflex-dom"; name = "reflex-dom"; }
    { src = sources.reflex-dom + "/reflex-dom-core"; name = "reflex-dom-core"; }
    { src = sources.servant-reflex; name = "servant-reflex"; }
    { src = sources.reflex; name = "reflex"; }
    { src = sources.patch; name = "patch"; }
    { src = sources.jsaddle + "/jsaddle"; name = "jsaddle"; }
    { src = sources.monoidal-containers + "/monoidal-containers"; name = "monoidal-containers"; }
  ])
  );
in
hsPkgs
```

## Precautions

1. You should really only use this for packages that are only in Hackage. If a package is not in Hackage, you I suggest you use `source-repository-package` in `cabal.project`.

2. Only one version of the package is overridden. All other version are left the way they are. For this reason you should probably contraint the versions of packages you override to the specific version you use.
