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

## Development

To build the package locally:

```bash
nix build .
```

The binary will be available at `./result/bin/helium`.

## License

This flake is licensed under the [MIT License](./LICENSE.md). The Helium browser itself is licensed under the [GPL-3.0 License](https://github.com/imputnet/helium/blob/main/LICENSE).
