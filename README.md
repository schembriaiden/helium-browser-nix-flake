# Helium Browser Nix Flake

A standalone Nix flake for the [Helium browser](https://helium.computer/), a private, fast, and honest web browser based on ungoogled-chromium.

## Usage

### Run directly

You can run Helium directly without installing it:

```bash
nix run github:schembriaiden/helium-browser-nix-flake
```

### Install in NixOS or Home Manager

Add this flake to your inputs:

```nix
inputs.helium = {
  url = "github:schembriaiden/helium-browser-nix-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add it to your packages:

```nix
environment.systemPackages = [
  inputs.helium.packages.${system}.default
];
```

### Using the overlay

You can also apply the overlay so `pkgs.helium` is available directly:

```nix
nixpkgs.overlays = [
  inputs.helium.overlays.default
];
```

Then use it anywhere as `pkgs.helium`:

```nix
environment.systemPackages = with pkgs; [
  helium
];
```

## Development

To build the package locally:

```bash
nix build .
```

The binary will be available at `./result/bin/helium`.

## Contributing

If you find something broken or not working as expected, feel free to open an issue or submit a pull request.

## License

This flake is licensed under the [MIT License](./LICENSE.md). The Helium browser itself is licensed under the [GPL-3.0 License](https://github.com/imputnet/helium/blob/main/LICENSE).
