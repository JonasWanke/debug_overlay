{
  inputs = {
    # https://github.com/NixOS/nixpkgs/pull/587442
    nixpkgs.url = "github:nixos/nixpkgs?ref=fdc28e399b28c24e279274962fe452f0c82d5bd8";
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

        flutter = pkgs.flutterPackages.v3_50;

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
