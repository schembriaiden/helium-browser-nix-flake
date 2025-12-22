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

        version = "0.7.7.1";

        srcs = {
          x86_64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
            sha256 = "sha256-aY9GwIDPTcskm55NluSyxkCHC6drd6BdBaNYZhrzlRE=";
          };
          aarch64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-arm64_linux.tar.xz";
            sha256 = "sha256-76hJ19/bHzdE1//keGF9imYkMHOy6VHpA56bxEkgwgA=";
          };
          x86_64-darwin = {
            url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_x86_64-macos.dmg";
            sha256 = "sha256-LtxzeBkECRML+q+qtcTl7uFoM97uZdU1PIcdDqhpd0Y=";
          };
          aarch64-darwin = {
            url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_arm64-macos.dmg";
            sha256 = "sha256-iFE2OigeG+sDfGKmuqqb6LKUyxhZ2Jcti+jLzeHMLYM=";
          };
        };

        helium = pkgs.stdenv.mkDerivation {
          pname = "helium";
          inherit version;

          src = pkgs.fetchurl (srcs.${system} or (throw "Unsupported system: ${system}"));

          nativeBuildInputs = with pkgs; [
            makeWrapper
          ] ++ pkgs.lib.optionals stdenv.isLinux [
            autoPatchelfHook
            copyDesktopItems
          ] ++ pkgs.lib.optionals stdenv.isDarwin [
            _7zz
          ];

          unpackCmd = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
            7zz x $src
          '';

          buildInputs = with pkgs; pkgs.lib.optionals stdenv.isLinux [
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

          autoPatchelfIgnoreMissingDeps = pkgs.lib.optionals pkgs.stdenv.isLinux [
            "libQt6Core.so.6"
            "libQt6Gui.so.6"
            "libQt6Widgets.so.6"
            "libQt5Core.so.5"
            "libQt5Gui.so.5"
            "libQt5Widgets.so.5"
          ];

          dontWrapQtApps = pkgs.stdenv.isLinux;

          installPhase = if pkgs.stdenv.isDarwin then ''
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
          '' else ''
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
              categories = [ "Network" "WebBrowser" ];
              terminal = false;
              mimeTypes = [ "text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
            })
          ];

          meta = with pkgs.lib; {
            description = "Private, fast, and honest web browser based on ungoogled-chromium";
            homepage = "https://helium.computer/";
            license = licenses.gpl3Only;
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
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
      in
      {
        packages.default = helium;
        packages.helium = helium;

        apps.default = app;
        apps.helium = app;

        devShells.default = pkgs.mkShell {
          buildInputs = [ helium ];
        };
      }
    );
}
