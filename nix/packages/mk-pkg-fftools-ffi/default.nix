{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
}:

let
  name = "fftools-ffi";
  packageLock = (import ../../../packages.lock.nix).${name};
  inherit (packageLock) version;

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };
  xctoolchainLipo = callPackage ../../utils/xctoolchain/lipo.nix { };
  ffmpeg = callPackage ../mk-pkg-ffmpeg/default.nix { };

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };

  # Patch fftools-ffi source for FFmpeg 7.1 compatibility
  patchedSource = pkgs.runCommand "${pname}-patched-source-${variant}-${version}" { } ''
    cp -r ${src} src
    chmod -R 777 src
    cd src
    # Define missing av_stream_get_end_pts macro
    sed -i '/#include "libavutil\/avassert.h"/a #define av_stream_get_end_pts(st) ((st)->duration != AV_NOPTS_VALUE ? (st)->start_time + (st)->duration : AV_NOPTS_VALUE)' ffmpeg.c
    cd ..
    cp -r src $out
  '';
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${variant}-${version}";
  pname = pname;
  inherit version;
  src = patchedSource;
  dontUnpack = true;
  enableParallelBuilding = true;
  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    xctoolchainLipo
  ];
  buildInputs = [
    ffmpeg
  ];
  configurePhase = ''
    export CFLAGS="-Wno-error -Wno-pointer-sign $CFLAGS"
    meson setup build $src \
      --native-file ${nativeFile} \
      --cross-file ${crossFile} \
      --prefix=$out
  '';
  buildPhase = ''
    meson compile -vC build
  '';
  installPhase = ''
    meson install -C build
  '';
}
