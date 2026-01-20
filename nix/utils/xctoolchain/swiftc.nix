{
  pkgs ? import ../default/pkgs.nix,
}:

let
  xcodeBase = pkgs.darwin.xcode;
  xcodeToolchain = "${xcodeBase}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain";
  # Use Xcode's built-in macOS SDK (matching Swift version)
  xcodeSdk = "${xcodeBase}/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
  swiftLibDir = "${xcodeToolchain}/usr/lib/swift/macosx";
in

pkgs.runCommand "mk-xctoolchain-swiftc" { } ''
  mkdir -p $out/{bin,nix-support}
  
  # Create a wrapper script that ALWAYS uses Xcode's SDK
  # This overrides any -sdk argument passed by meson
  cat > $out/bin/swiftc << 'WRAPPER'
#!/bin/bash
# Filter out any -sdk arguments and force use of Xcode's SDK
args=()
skip_next=false
for arg in "$@"; do
  if $skip_next; then
    skip_next=false
    continue
  fi
  if [ "$arg" = "-sdk" ]; then
    skip_next=true
    continue
  fi
  args+=("$arg")
done

exec ${xcodeToolchain}/usr/bin/swiftc -sdk ${xcodeSdk} "''${args[@]}"
WRAPPER
  chmod +x $out/bin/swiftc
  
  # Also create swift wrapper
  cat > $out/bin/swift << 'WRAPPER'
#!/bin/bash
exec ${xcodeToolchain}/usr/bin/swift -sdk ${xcodeSdk} "$@"
WRAPPER
  chmod +x $out/bin/swift
  
  cat > $out/nix-support/setup-hook << EOF
export SWIFT_LIB_DYNAMIC=${swiftLibDir}
EOF
''
