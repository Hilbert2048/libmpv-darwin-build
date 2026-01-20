final: prev: {
  darwin = prev.darwin.overrideScope (
    final: prev: {
      # Xcode 16 - supports C++20 and compatible with nixpkgs meson
      xcode_16 = prev.xcode.overrideAttrs (prev: {
        outputHash = "sha256-wQjNuFZu/cN82mEEQbC1MaQt39jLLDsntsbnDidJFEs=";
      });
      xcode = final.xcode_16;
    }
  );
}
