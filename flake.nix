{
  inputs = {
    # https://github.com/NixOS/nixpkgs/pull/556426
    nixpkgs.url = "github:nixos/nixpkgs?ref=376b94add7951eb8c87c6670e72ac4f35a1368d3";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        flutter = pkgs.flutterPackages.v3_47;

        # Android
        androidSdkArgs = {
          buildToolsVersions = [ "33.0.1" ];
          platformVersions = [
            "33"
            "34"
            "35"
          ];
        };
        androidComposition = pkgs.androidenv.composeAndroidPackages androidSdkArgs;
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell =
          with pkgs;
          mkShell {
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            FLUTTER_ROOT = flutter;
            buildInputs = [
              androidSdk
              flutter
            ];
          };
      }
    );
}
