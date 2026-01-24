{
  description = "A Nix flake for the Helium browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        versions = {
          linux = "0.8.3.1";
          darwin = "0.8.3.1";
        };

        version = if pkgs.stdenv.isDarwin then versions.darwin else versions.linux;

        srcs = {
          x86_64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${versions.linux}/helium-${versions.linux}-x86_64_linux.tar.xz";
            hash = "sha256-WVeqX8FeOFnfzZDPWqdSAK8qb/CMKAKVAhglcfX/sCY=";
          };
          aarch64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${versions.linux}/helium-${versions.linux}-arm64_linux.tar.xz";
            hash = "sha256-kWdjLBRe0jg1zvedtSnUarenuG6wK9WExZV6wW82xxo=";
          };
          x86_64-darwin = {
            url = "https://github.com/imputnet/helium-macos/releases/download/${versions.darwin}/helium_${versions.darwin}_x86_64-macos.dmg";
            hash = "sha256-T0ktNMm3U5+6jXtaF+94KQip04YCUt7+JT3bqWRQ6zY=";
          };
          aarch64-darwin = {
            url = "https://github.com/imputnet/helium-macos/releases/download/${versions.darwin}/helium_${versions.darwin}_arm64-macos.dmg";
            hash = "sha256-5DKOByUwqLIdNO1U2OHY5tHivAwbYzFOaYO7wcy/QfI=";
          };
        };

        helium = pkgs.stdenv.mkDerivation {
          pname = "helium";
          inherit version;

          src = pkgs.fetchurl (srcs.${system} or (throw "Unsupported system: ${system}"));

          nativeBuildInputs = with pkgs;
            [
              makeWrapper
            ]
            ++ pkgs.lib.optionals stdenv.isLinux [
              autoPatchelfHook
              copyDesktopItems
            ]
            ++ pkgs.lib.optionals stdenv.isDarwin [
              _7zz
            ];

          unpackCmd = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
            7zz x $src
          '';

          buildInputs = with pkgs;
            pkgs.lib.optionals stdenv.isLinux [
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
              pipewire
              systemd
              vulkan-loader
              wayland
              libxshmfence
              libuuid
              kdePackages.qtbase
            ];

          autoPatchelfIgnoreMissingDeps = pkgs.lib.optionals pkgs.stdenv.isLinux [
            "libQt6Core.so.6"
            "libQt6Gui.so.6"
            "libQt6Widgets.so.6"
            "libQt5Core.so.5"
            "libQt5Gui.so.5"
            "libQt5Widgets.so.5"
          ];

          dontWrapQtApps = pkgs.stdenv.isLinux;

          installPhase =
            if pkgs.stdenv.isDarwin
            then ''
              runHook preInstall

              mkdir -p $out/Applications/Helium.app
              cp -r . $out/Applications/Helium.app

              mkdir -p $out/bin
              makeWrapper $out/Applications/Helium.app/Contents/MacOS/Helium $out/bin/helium \
                --add-flags "--disable-component-update" \
                --add-flags "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'" \
                --add-flags "--check-for-update-interval=0" \
                --add-flags "--disable-background-networking"

              runHook postInstall
            ''
            else ''
              runHook preInstall

              mkdir -p $out/bin $out/opt/helium
              cp -r * $out/opt/helium

              # The binary is named 'helium' as of version 0.8.3.1
              makeWrapper $out/opt/helium/helium $out/bin/helium \
                --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath (with pkgs; [
                libGL
                libvdpau
                libva
                pipewire
              ])}" \
                --add-flags "--ozone-platform-hint=auto" \
                --add-flags "--enable-features=WaylandWindowDecorations" \
                --add-flags "--disable-component-update" \
                --add-flags "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'" \
                --add-flags "--check-for-update-interval=0" \
                --add-flags "--disable-background-networking"

              # Install icon
              mkdir -p $out/share/icons/hicolor/256x256/apps
              cp $out/opt/helium/product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png

              runHook postInstall
            '';

          desktopItems = pkgs.lib.optionals pkgs.stdenv.isLinux [
            (pkgs.makeDesktopItem {
              name = "helium";
              exec = "helium %U";
              icon = "helium";
              desktopName = "Helium";
              genericName = "Web Browser";
              categories = ["Network" "WebBrowser"];
              terminal = false;
              mimeTypes = ["text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https"];
            })
          ];

          meta = with pkgs.lib; {
            description = "Private, fast, and honest web browser based on ungoogled-chromium";
            homepage = "https://helium.computer/";
            license = licenses.gpl3Only;
            platforms = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
            mainProgram = "helium";
          };
        };

        app = {
          type = "app";
          program = "${helium}/bin/helium";
          meta = {
            inherit (helium.meta) description homepage license platforms;
          };
        };
      in {
        packages.default = helium;
        packages.helium = helium;

        apps.default = app;
        apps.helium = app;

        devShells.default = pkgs.mkShell {
          buildInputs = [helium];
        };
      }
    );
}
