{
  description = "A Nix flake for the Helium browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        version = "0.7.6.1";

        srcs = {
          x86_64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
            sha256 = "12z2zhbchyq0jzhld57inkaxfwm2z8gxkamnnwcvlw96qqr0rga4";
          };
          aarch64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64_linux.tar.xz";
            sha256 = "1fasgax0d74nlxziqwh10x5xh25p82gnq9dh5qll2wc14hc98jmn";
          };
        };

        helium = pkgs.stdenv.mkDerivation {
          pname = "helium";
          inherit version;

          src = pkgs.fetchurl (srcs.${system} or (throw "Unsupported system: ${system}"));

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
            copyDesktopItems
          ];

          buildInputs = with pkgs; [
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            expat
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gtk3
            libGL
            xorg.libX11
            xorg.libXScrnSaver
            xorg.libXcomposite
            xorg.libXcursor
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXrandr
            xorg.libXrender
            xorg.libXtst
            libdrm
            libgbm
            libpulseaudio
            xorg.libxcb
            libxkbcommon
            mesa
            nspr
            nss
            pango
            systemd
            vulkan-loader
            wayland
            libxshmfence
            libuuid
            kdePackages.qtbase
          ];

          autoPatchelfIgnoreMissingDeps = [
            "libQt6Core.so.6"
            "libQt6Gui.so.6"
            "libQt6Widgets.so.6"
            "libQt5Core.so.5"
            "libQt5Gui.so.5"
            "libQt5Widgets.so.5"
          ];

          dontWrapQtApps = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/opt/helium
            cp -r * $out/opt/helium

            # The binary is named 'chrome' in the tarball
            makeWrapper $out/opt/helium/chrome $out/bin/helium \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath (with pkgs; [
                libGL
                libvdpau
                libva
              ])}" \
              --add-flags "--ozone-platform-hint=auto" \
              --add-flags "--enable-features=WaylandWindowDecorations"

            # Install icon
            mkdir -p $out/share/icons/hicolor/256x256/apps
            cp $out/opt/helium/product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png
            
            runHook postInstall
          '';

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "helium";
              exec = "helium %U";
              icon = "helium";
              desktopName = "Helium";
              genericName = "Web Browser";
              categories = [ "Network" "WebBrowser" ];
              terminal = false;
              mimeTypes = [ "text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
            })
          ];

          meta = with pkgs.lib; {
            description = "Private, fast, and honest web browser based on ungoogled-chromium";
            homepage = "https://helium.computer/";
            license = licenses.gpl3Only;
            platforms = [ "x86_64-linux" "aarch64-linux" ];
            mainProgram = "helium";
          };
        };
      in
      {
        packages.default = helium;
        packages.helium = helium;

        apps.default = utils.lib.mkApp { drv = helium; };
        apps.helium = utils.lib.mkApp { drv = helium; };

        devShells.default = pkgs.mkShell {
          buildInputs = [ helium ];
        };
      }
    );
}
