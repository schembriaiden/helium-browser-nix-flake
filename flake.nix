{
  description = "A Nix flake for the Helium browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs 26.11 and later no longer support x86_64-darwin. Keep that
    # platform available with the supported Darwin maintenance branch.
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-darwin,
    utils,
  }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = import (if system == "x86_64-darwin" then nixpkgs-darwin else nixpkgs) {
          inherit system;
          config.allowUnfree = true;
        };

        versions = {
          linux = "0.18.1.1";
          darwin = "0.18.1.1";
        };

        version = if pkgs.stdenv.hostPlatform.isDarwin then versions.darwin else versions.linux;

        srcs = {
          x86_64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${versions.linux}/helium-${versions.linux}-x86_64_linux.tar.xz";
            hash = "sha256-n001I57qGLKQhGIhh0JlrCqGN63/lU32n973fWsVBCw=";
          };
          aarch64-linux = {
            url = "https://github.com/imputnet/helium-linux/releases/download/${versions.linux}/helium-${versions.linux}-arm64_linux.tar.xz";
            hash = "sha256-UJ6kv8YX//RW9FhIFIlMbacbP+W20JY3sItPPHar7J4=";
          };
          x86_64-darwin = {
            url = "https://github.com/imputnet/helium-macos/releases/download/${versions.darwin}/helium_${versions.darwin}_x86_64-macos.dmg";
            hash = "sha256-bjWOsCgopWjfcNLNE67U9vfbI4lsEXh6wbnGIbxdbjQ=";
          };
          aarch64-darwin = {
            url = "https://github.com/imputnet/helium-macos/releases/download/${versions.darwin}/helium_${versions.darwin}_arm64-macos.dmg";
            hash = "sha256-QY5zOYBxYcvaxC26cFIGeZcFdtUPWqTzCj8IYv60odk=";
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
            ++ pkgs.lib.optionals stdenv.hostPlatform.isLinux [
              autoPatchelfHook
              copyDesktopItems
            ]
            ++ pkgs.lib.optionals stdenv.hostPlatform.isDarwin [
              _7zz
            ];

          unpackCmd = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            7zz x $src
          '';

          buildInputs = with pkgs;
            pkgs.lib.optionals stdenv.hostPlatform.isLinux [
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
              libx11
              libxscrnsaver
              libxcomposite
              libxcursor
              libxdamage
              libxext
              libxfixes
              libxi
              libxrandr
              libxrender
              libxtst
              libdrm
              libgbm
              libpulseaudio
              libxcb
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

          autoPatchelfIgnoreMissingDeps = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            "libQt6Core.so.6"
            "libQt6Gui.so.6"
            "libQt6Widgets.so.6"
            "libQt5Core.so.5"
            "libQt5Gui.so.5"
            "libQt5Widgets.so.5"
          ];

          dontWrapQtApps = pkgs.stdenv.hostPlatform.isLinux;

          installPhase =
            if pkgs.stdenv.hostPlatform.isDarwin
            then ''
              runHook preInstall

              mkdir -p $out/Applications
              # Since 0.17.2.1 the DMG extracts as a `Helium/` volume directory
              # containing `Helium.app` (plus an `Applications` symlink and
              # `.background`). Older DMGs extracted `Helium.app` directly, so
              # the source root was the bundle itself. Handle both layouts.
              if [ -d Helium.app ]; then
                cp -R Helium.app $out/Applications/Helium.app
              elif [ -d Contents ]; then
                cp -R . $out/Applications/Helium.app
              else
                echo "Could not find Helium.app in the extracted DMG:" >&2
                ls -la >&2
                exit 1
              fi

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

              # The binary is named 'helium'
              makeWrapper $out/opt/helium/helium $out/bin/helium \
                --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath (with pkgs; [
                libGL
                libvdpau
                libva
                pipewire
                alsa-lib
                libpulseaudio
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

          desktopItems = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            (pkgs.makeDesktopItem {
              name = "helium";
              exec = "helium %U";
              icon = "helium";
              desktopName = "Helium";
              genericName = "Web Browser";
              comment = "Private, fast, and honest web browser";
              categories = ["Network" "WebBrowser"];
              terminal = false;
              mimeTypes = ["text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https"];
            })
          ];

          meta = with pkgs.lib; {
            description = "Private, fast, and honest web browser";
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
    )
    // {
      overlays.default = final: prev: {
        helium = self.packages.${prev.stdenv.hostPlatform.system}.default;
      };
    };
}
