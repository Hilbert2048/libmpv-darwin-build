{
  pkgs ? import ../default/pkgs.nix,
}:

let
  xcodeBase = pkgs.darwin.xcode;
  xcodeToolchain = "${xcodeBase}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain";
  xcodeSdk = "${xcodeBase}/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
  
  # Import our swiftc wrapper
  xctoolchainSwiftc = pkgs.callPackage ./swiftc.nix { };
in

pkgs.runCommand "mk-xctoolchain-xcrun" { } ''
  mkdir -p $out/bin
  
  # Create a wrapper script for xcrun that returns OUR wrapper path for swiftc
  cat > $out/bin/xcrun << 'WRAPPER'
#!/bin/bash
# Custom xcrun wrapper for Nix builds - returns our swiftc wrapper

case "$*" in
  *"-find swiftc"*)
    # Return our swiftc wrapper instead of Xcode's directly
    echo "${xctoolchainSwiftc}/bin/swiftc"
    ;;
  *"-find swift"*)
    echo "${xctoolchainSwiftc}/bin/swift"
    ;;
  *)
    # Fall back to real xcrun for other commands
    exec /usr/bin/xcrun "$@"
    ;;
esac
WRAPPER
  chmod +x $out/bin/xcrun
''
