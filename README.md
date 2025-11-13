# OneTrainer Nix Flake

A comprehensive Nix flake for [OneTrainer](https://github.com/Nerogar/OneTrainer) - a tool for training diffusion models like Stable Diffusion, FLUX, and more.

## Features

- **Full CUDA Support**: GPU acceleration for training
- **Multiple Entry Points**: GUI, CLI, and model conversion tools
- **Complete Dependencies**: All required Python packages included
- **Development Environment**: Ready-to-use dev shell

## Usage

### Run GUI directly
```bash
nix run github:celesrenata/OneTrainer-flake
# or specifically
nix run github:celesrenata/OneTrainer-flake#onetrainer-ui
```

### Run CLI training
```bash
nix run github:celesrenata/OneTrainer-flake#onetrainer-cli -- --help
```

### Run model converter
```bash
nix run github:celesrenata/OneTrainer-flake#onetrainer-convert
```

### Development shell
```bash
nix develop github:celesrenata/OneTrainer-flake
```

### Install permanently
```bash
nix profile install github:celesrenata/OneTrainer-flake
# Then use: onetrainer-ui, onetrainer-cli, onetrainer-convert
```

## Local Development

```bash
git clone https://github.com/celesrenata/OneTrainer-flake
cd OneTrainer-flake
nix develop
# Now you can run scripts directly:
python scripts/train_ui.py
```

## Requirements

- **Nix with flakes enabled**
- **NVIDIA GPU with CUDA drivers** (for GPU training)
- **Sufficient RAM** (8GB+ recommended)
- **Storage space** for models and datasets

## Available Commands

After installation, you'll have access to:

- `onetrainer-ui` - Launch the GUI interface
- `onetrainer-cli` - Command-line training interface  
- `onetrainer-convert` - Model conversion utility
- `onetrainer` - Alias for `onetrainer-ui`

## GPU Support

This flake includes full CUDA support with:
- PyTorch with CUDA backend
- CUDA toolkit and cuDNN
- Proper library path configuration
- GPU-accelerated training capabilities

## Supported Models

OneTrainer supports training for:
- Stable Diffusion (1.5, 2.0, 2.1, 3.x, SDXL)
- FLUX.1
- Würstchen v2
- PixArt Alpha
- Qwen Image
- Sana
- Hunyuan Video
- And more!

## Training Methods

- **Fine-tuning**: Full model training
- **LoRA**: Low-rank adaptation
- **Embeddings**: Textual inversion
- **Multi-resolution training**
- **Aspect ratio bucketing**
- **Advanced optimizers** (AdamW, Lion, Prodigy, etc.)
