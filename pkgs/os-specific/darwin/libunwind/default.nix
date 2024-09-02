{
  lib,
  apple-sdk,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "libunwind";
  inherit (apple-sdk) version;

  buildCommand = ''
    mkdir -p "$out/lib/pkgconfig"
    cat <<EOF > "$out/lib/pkgconfig/libunwind.pc"
    Name: libunwind
    Description: An implementation of the HP libunwind interface
    Version: ${finalAttrs.version}
    Libs: -lunwind
    EOF
  '';

  meta = {
    description = "Compatibility package for libunwind on Darwin";
    maintainers = lib.teams.darwin.members;
    platforms = lib.platforms.darwin;
    pkgConfigModules = [ "libunwind" ];
  };
})
