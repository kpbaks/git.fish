{
  description = "git.fish - fish shell git abbreviations and interactive integrations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "git.fish";
            version = self.shortRev or self.dirtyShortRev or "unknown";
            src = self;
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp -r functions completions conf.d $out/
              runHook postInstall
            '';
          };
        }
      );
    };
}
