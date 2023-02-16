{
  description = "A very basic flake";

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-darwin;
      nodejs = pkgs.nodejs-16_x;
    in
    with pkgs; {

      devShell.x86_64-darwin = mkShell { buildInputs = [ nodejs yarn ]; };

    };
}
