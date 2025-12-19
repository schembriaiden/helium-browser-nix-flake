# Helium Browser Nix Flake

A standalone Nix flake for the [Helium browser](https://helium.computer/), a private, fast, and honest web browser based on ungoogled-chromium.

## Usage

### Run directly

You can run Helium directly without installing it:

```bash
nix run github:vikingnope/helium-browser-nix-flake
```

### Install in NixOS or Home Manager

Add this flake to your inputs:

```nix
inputs.helium.url = "github:vikingnope/helium-browser-nix-flake";
```

Then add it to your packages:

```nix
environment.systemPackages = [
  inputs.helium.packages.${system}.default
];
```

## Features

- **Wayland Support**: Enabled by default with `--ozone-platform-hint=auto`.
- **Desktop Integration**: Includes a `.desktop` file and high-resolution icons.
- **Auto-Patchelf**: Automatically fixes library dependencies for the pre-compiled binaries.

## Development

To build the package locally:

```bash
nix build .
```

The binary will be available at `./result/bin/helium`.

## License

This flake is licensed under the MIT License. The Helium browser itself is licensed under the GPL-3.0 License.
