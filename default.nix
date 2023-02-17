{ pkgs ? import <nixpkgs> { } }:

with pkgs;
stdenv.mkDerivation
{
  name = "MyScrapingApp";
  version = "1.0.0";

  buildInputs = [ nodejs-16_x yarn ];

  src = nix-gitignore.gitignoreSource [ ] ./.;

  buildPhase = ''
    HOME=$TMP yarn install --frozen-lockfile
    mkdir -p ./dest
    yarn tsc -p .
    yarn install --frozen-lockfile --ignore-scripts --production
  '';

  installPhase = ''
    mkdir $out
    mv ./node_modules ./dest $out/
  '';
}
