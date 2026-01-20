# Fix meson for newer Xcode/libc++ that removed _LIBCPP_ENABLE_ASSERTIONS
# The new libc++ requires _LIBCPP_HARDENING_MODE instead
final: prev: {
  meson = prev.meson.overrideAttrs (oldAttrs: {
    # Patch the setup hook to not add -D_LIBCPP_ENABLE_ASSERTIONS=1
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace setup-hook.sh \
        --replace-quiet '_LIBCPP_ENABLE_ASSERTIONS=1' '_LIBCPP_HARDENING_MODE=0' || true
      substituteInPlace data/macros/meson-sample.fish \
        --replace-quiet '_LIBCPP_ENABLE_ASSERTIONS=1' '_LIBCPP_HARDENING_MODE=0' || true
    '';
  });
}
