# OneTrainer Nix Flake

A Nix flake for [OneTrainer](https://github.com/Nerogar/OneTrainer) - a one-stop solution for all your stable diffusion training needs.

## Usage

### Run directly
```bash
nix run github:celesrenata/OneTrainer-flake
```

### Development shell
```bash
nix develop github:celesrenata/OneTrainer-flake
```

### Install
```bash
nix profile install github:celesrenata/OneTrainer-flake
```

## Local Development

```bash
git clone https://github.com/celesrenata/OneTrainer-flake
cd OneTrainer-flake
nix develop
```

## Requirements

- Nix with flakes enabled
- For GPU support, ensure CUDA drivers are available on your system

## Note

This flake includes CPU-only PyTorch by default for maximum compatibility. For GPU training, you may need to install CUDA-enabled PyTorch separately or modify the flake.