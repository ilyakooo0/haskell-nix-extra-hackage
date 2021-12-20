{ pkgs }:

# [{ name, src, cabal-file ? "${name}.cabal" }]
pkgSrcs:
let
  undefined = builtins.abort "undefined";
  mockInput = {
    system = undefined;
    compiler = undefined;
    flags = undefined;
    pkgs = undefined;
    hsPkgs = undefined;
    pkgconfPkgs = undefined;
    errorHandler = undefined;
    config = undefined;
  };
  mkPkg = p: {
    out = pkgs.haskell-nix.callCabalToNix p;
    inherit p;
  };
  hPkgs = builtins.map mkPkg pkgSrcs;
  hPkgsReady = builtins.map
    ({ p, out }:
      let mockPkg = import out mockInput; in
      {
        "${mockPkg.package.identifier.name}" = {
          "${mockPkg.package.identifier.version}" =
            {
              # this is fine since the path contains the hash
              sha256 = builtins.hashString "sha256" (toString p.src);
              revisions =
                let rev = {
                  outPath = out;
                  revNum = 0;
                  sha256 = builtins.hashFile "sha256" "${p.src}/${p.cabal-file or "${p.name}.cabal"}";
                };
                in
                { r0 = rev; default = rev; };
            };
        };
      })
    hPkgs;

  index = pkgs.runCommand "index.tar.gz" { } ''
    ${ builtins.concatStringsSep "\n"
      (builtins.map ({p, out}:
      let mockPkg = import out mockInput;
          d = "${mockPkg.package.identifier.name}/${mockPkg.package.identifier.version}/";
      in ''
        mkdir -p ${d}
        echo '{"signatures":[],"signed":{"_type":"Targets","expires":null,"targets":{"<repo>/package/${mockPkg.package.identifier.name}-${mockPkg.package.identifier.version}.tar.gz":{"hashes":{"md5":"","sha256":""},"length":0}},"version":0}}' > ${d}/package.json
        cp "${p.src}/${p.cabal-file or "${p.name}.cabal"}" ${d}
      '')
      hPkgs)
    }
    find . -type f | xargs touch -m -a -t 7101010000
    find . -type f -printf '%P\n' | xargs tar czf $out
  '';
in
{
  extra-hackages = [ (pkgs.lib.foldl (a: b: a // b) { } hPkgsReady) ];
  extra-hackage-tarballs = [
    {
      name = "local-package-overrides-hackage";
      inherit index;
    }
  ];
}
