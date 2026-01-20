{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "libplacebo";
  version = "7.351.0";

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  pname = import ../../utils/name/package.nix name;
  
  # Use fetchgit with submodules to get all 3rdparty dependencies
  src = pkgs.fetchgit {
    url = "https://code.videolan.org/videolan/libplacebo.git";
    rev = "v${version}";
    hash = "sha256-a+WxAyocTDaY6d6RhR/WJ048eA5xEieXfSC5cFsGvOk=";
    fetchSubmodules = true;
  };
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  pname = pname;
  inherit version src;
  dontUnpack = true;
  enableParallelBuilding = true;
  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pkgs.python3
  ];

  configurePhase = ''
    meson setup build $src \
      --cross-file ${crossFile} \
      --prefix=$out \
      -Dvulkan=disabled \
      -Dd3d11=disabled \
      -Dopengl=disabled \
      -Dglslang=disabled \
      -Dshaderc=disabled \
      -Ddemos=false \
      -Dtests=false \
      -Dbench=false \
      -Dfuzz=false \
      -Dlcms=disabled \
      -Ddovi=disabled \
      -Dlibdovi=disabled \
      -Dunwind=disabled
  '';
  buildPhase = ''
    meson compile -vC build
  '';
  installPhase = ''
    meson install -C build
  '';
}


