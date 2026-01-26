{
  pkgs ? import ../default/pkgs.nix,
  os ? import ../default/os.nix,
  arch ? pkgs.callPackage ../default/arch.nix { },
}:

pkgs.runCommand "mk-cross-file-${os}-${arch}.ini" { } ''
  cp ${../../../cross-files/${os}-${arch}.ini} cross-file.ini
  sed -i "s|/Applications/Xcode.app|${pkgs.darwin.xcode}|g" cross-file.ini
  # Bump iOS SDK version to 11.0 for VTCopySupportedPropertyDictionaryForEncoder
  sed -i "s|-miphoneos-version-min=9.0|-miphoneos-version-min=12.0|g" cross-file.ini
  cp cross-file.ini $out
''
