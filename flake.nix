{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
{
      devShell.x86_64-linux = let pkgs = nixpkgs.legacyPackages.x86_64-linux; in with pkgs; mkShell {
        buildInputs = [ nodejs-16_x yarn kind gnumake ];
      };

      devShell.x86_64-darwin = let pkgs = nixpkgs.legacyPackages.x86_64-darwin; in with pkgs; mkShell {
        buildInputs = [ nodejs-16_x yarn kind gnumake ];
      };
    };
}
