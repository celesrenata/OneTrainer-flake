{
  description = "OneTrainer - A comprehensive tool for training diffusion models";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
        
        # Use Python 3.11 as recommended by OneTrainer
        python = pkgs.python312;
        
        # Create Python environment with core dependencies
        onetrainer-env = python.withPackages (ps: with ps; [
          # Build essentials
          pip
          setuptools
          wheel
          
          # Base requirements from requirements-global.txt
          numpy
          opencv4
          pillow
          tqdm
          pyyaml
          huggingface-hub
          scipy
          matplotlib
          
          # PyTorch with CUDA support
          pytorch-bin
          
          # ML/AI libraries
          safetensors
          tensorboard
          transformers
          sentencepiece
          
          # UI components
          tkinter
          
          # UI components
          tkinter
          
          # Utilities
          psutil
          requests
          
          # Additional dependencies
          imagesize
          fabric
          omegaconf
          pooch
          av
          yt-dlp
          deepdiff
          scenedetect
        ]);

        onetrainer = pkgs.stdenv.mkDerivation rec {
          pname = "onetrainer";
          version = "unstable-2024-01-07";
          
          src = pkgs.fetchFromGitHub {
            owner = "Nerogar";
            repo = "OneTrainer";
            rev = "ccc050125c65f533a4df5312ed531cb340f10b09";
            sha256 = "sha256-hwGQB94sr9WFiVONhgNeBdYqCkrJEj/7mgr8WGAAX6o=";
          };
          
          nativeBuildInputs = with pkgs; [
            makeWrapper
            pkg-config
          ];
          
          buildInputs = with pkgs; [
            onetrainer-env
            
            # System libraries for GUI
            xorg.libX11
            xorg.libXext
            xorg.libXrender
            libGL
            glib
            gtk3
            
            # CUDA support
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            
            # System dependencies
            stdenv.cc.cc.lib
            zlib
            openssl
            libtommath
            tcl
            tk
            tk.dev
          ];
          
          # Don't build, just install
          dontBuild = true;
          
          installPhase = ''
            runHook preInstall
            
            # Create directories
            mkdir -p $out/{bin,share/onetrainer}
            
            # Copy all source files
            cp -r . $out/share/onetrainer/
            
            # Create wrapper scripts for different entry points
            makeWrapper ${onetrainer-env}/bin/python $out/bin/onetrainer-ui \
              --add-flags "$out/share/onetrainer/scripts/train_ui.py" \
              --set PYTHONPATH "$out/share/onetrainer:$out/share/onetrainer/venv/lib/python3.11/site-packages" \
              --set HF_HUB_DISABLE_XET "1" \
              --set CUDA_PATH "${pkgs.cudaPackages.cudatoolkit}" \
              --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath buildInputs}" \
              --chdir "$out/share/onetrainer"
            
            makeWrapper ${onetrainer-env}/bin/python $out/bin/onetrainer-cli \
              --add-flags "$out/share/onetrainer/scripts/train.py" \
              --set PYTHONPATH "$out/share/onetrainer:$out/share/onetrainer/venv/lib/python3.11/site-packages" \
              --set HF_HUB_DISABLE_XET "1" \
              --set CUDA_PATH "${pkgs.cudaPackages.cudatoolkit}" \
              --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath buildInputs}" \
              --chdir "$out/share/onetrainer"
            
            makeWrapper ${onetrainer-env}/bin/python $out/bin/onetrainer-convert \
              --add-flags "$out/share/onetrainer/scripts/convert_model_ui.py" \
              --set PYTHONPATH "$out/share/onetrainer:$out/share/onetrainer/venv/lib/python3.11/site-packages" \
              --set HF_HUB_DISABLE_XET "1" \
              --set CUDA_PATH "${pkgs.cudaPackages.cudatoolkit}" \
              --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath buildInputs}" \
              --chdir "$out/share/onetrainer"
            
            # Create legacy onetrainer command that points to UI
            ln -s $out/bin/onetrainer-ui $out/bin/onetrainer
            
            runHook postInstall
          '';
          
          meta = with pkgs.lib; {
            description = "A comprehensive tool for training diffusion models like Stable Diffusion, FLUX, and more";
            longDescription = ''
              OneTrainer is a comprehensive tool for training various diffusion models including:
              - Stable Diffusion (1.5, 2.0, 2.1, 3.x, SDXL)
              - FLUX.1
              - Würstchen v2
              - PixArt Alpha
              - And many more
              
              Features both GUI and CLI interfaces with support for LoRA, fine-tuning,
              embeddings, and advanced training techniques.
            '';
            homepage = "https://github.com/Nerogar/OneTrainer";
            license = licenses.asl20;
            platforms = platforms.linux;
            maintainers = [ ];
          };
        };

      in {
        packages = {
          default = onetrainer;
          onetrainer = onetrainer;
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            onetrainer-env
            git
            curl
            wget
            
            # CUDA development
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            
            # System libraries
            xorg.libX11
            libGL
            gtk3
            
            # Development tools
            ruff
            black
          ];
          
          shellHook = ''
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (with pkgs; [ cudaPackages.cudatoolkit cudaPackages.cudnn libGL ])}"
            export HF_HUB_DISABLE_XET=1
            
            echo "OneTrainer development environment"
            echo "CUDA Path: $CUDA_PATH"
            echo "Python: $(python --version)"
            echo ""
            echo "Available commands:"
            echo "  python scripts/train_ui.py    - Start GUI"
            echo "  python scripts/train.py       - CLI training"
            echo "  python scripts/convert_model_ui.py - Model converter GUI"
          '';
        };
        
        apps = {
          default = {
            type = "app";
            program = "${onetrainer}/bin/onetrainer-ui";
          };
          
          onetrainer-ui = {
            type = "app";
            program = "${onetrainer}/bin/onetrainer-ui";
          };
          
          onetrainer-cli = {
            type = "app";
            program = "${onetrainer}/bin/onetrainer-cli";
          };
          
          onetrainer-convert = {
            type = "app";
            program = "${onetrainer}/bin/onetrainer-convert";
          };
        };
      });
}
