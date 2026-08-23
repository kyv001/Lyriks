{
  description = "A development environment for Lyriks";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
  let systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            kdePackages.plasma-sdk
            kdePackages.qtdeclarative
            kdePackages.plasma-workspace
            kdePackages.libplasma
            kdePackages.kirigami
          ];

          shellHook = ''
            export QML2_IMPORT_PATH=''$QML2_IMPORT_PATH:\
            ${pkgs.kdePackages.qtdeclarative}/lib/qt-6/qml:\
            ${pkgs.kdePackages.libplasma}/lib/qt-6/qml:\
            ${pkgs.kdePackages.plasma-workspace}/lib/qt-6/qml:\
            ${pkgs.kdePackages.plasma-desktop}/lib/qt-6/qml:\
            ${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml
            export QML_IMPORT_PATH=''$QML2_IMPORT_PATH
          '';
        };
      }
    );
  };
}
