{
  description = "OneTrainer - A comprehensive tool for training diffusion models";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Overlay to ensure consistent OpenSSL version across all packages
        openssl-overlay = final: prev: {
          python312Packages = prev.python312Packages.override {
            overrides = python-final: python-prev: {
              cryptography = python-prev.cryptography.override {
                openssl = final.openssl_3_6;
              };
              paramiko = python-prev.paramiko.override {
                cryptography = python-final.cryptography;
              };
            };
          };
        };
        
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
          overlays = [ openssl-overlay ];
        };
        
        # Use Python 3.11 as recommended by OneTrainer
        python = pkgs.python312;
        
        # Custom Python packages not in nixpkgs
        dadaptation = python.pkgs.buildPythonPackage rec {
          pname = "dadaptation";
          version = "3.2";
          pyproject = true;
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-3o6CidVr/e4MjjyjUxQyldikg2O8sC1oaKcINUtHzMA=";
          };
          build-system = with python.pkgs; [ setuptools ];
          dependencies = with python.pkgs; [ torch ];
          meta = with pkgs.lib; {
            description = "D-Adaptation optimizer for PyTorch";
            homepage = "https://pypi.org/project/dadaptation/";
            license = licenses.mit;
          };
        };
        
        prodigyopt = python.pkgs.buildPythonPackage rec {
          pname = "prodigyopt";
          version = "1.1.2";
          pyproject = true;
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-9u90lEiVybmgBF5V/dBNB72wO58Josd+LsdyydHs4V8=";
          };
          build-system = with python.pkgs; [ setuptools ];
          dependencies = with python.pkgs; [ torch ];
          meta = with pkgs.lib; {
            description = "Prodigy optimizer for PyTorch";
            homepage = "https://pypi.org/project/prodigyopt/";
            license = licenses.mit;
          };
        };
        
        schedulefree = python.pkgs.buildPythonPackage rec {
          pname = "schedulefree";
          version = "1.4.1";
          pyproject = true;
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-ae8lYB0fwNjdAMs2+a94gz+It4RvG7bd7MnxRPPp98s=";
          };
          build-system = with python.pkgs; [ hatchling ];
          dependencies = with python.pkgs; [ torch ];
          meta = with pkgs.lib; {
            description = "Schedule-free optimizer for PyTorch";
            homepage = "https://pypi.org/project/schedulefree/";
            license = licenses.mit;
          };
        };
        
        invisible-watermark = python.pkgs.buildPythonPackage rec {
          pname = "invisible-watermark";
          version = "0.2.0";
          pyproject = true;
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
          build-system = with python.pkgs; [ setuptools ];
          dependencies = with python.pkgs; [ pillow opencv4 torch ];
          meta = with pkgs.lib; {
            description = "Invisible watermark for images";
            homepage = "https://pypi.org/project/invisible-watermark/";
            license = licenses.mit;
          };
        };
        
        gguf = python.pkgs.buildPythonPackage rec {
          pname = "gguf";
          version = "0.17.1";
          pyproject = true;
          src = pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-Nq1xqtkAo+dfyU6+lupgKfA6TkS+difvetPQPox7y1M=";
          };
          build-system = with python.pkgs; [ poetry-core ];
          dependencies = with python.pkgs; [ numpy pyyaml tqdm ];
          meta = with pkgs.lib; {
            description = "GGUF file format support";
            homepage = "https://pypi.org/project/gguf/";
            license = licenses.mit;
          };
        };
        
        mgds = python.pkgs.buildPythonPackage rec {
          pname = "mgds";
          version = "0.1.0";
          pyproject = true;
          src = pkgs.fetchFromGitHub {
            owner = "Nerogar";
            repo = "mgds";
            rev = "40190b7";
            sha256 = "sha256-rbEvbQJk4BZuJFMpQSVdmEoh5erX/uoC0lj+CvNEztM=";
          };
          build-system = with python.pkgs; [ setuptools setuptools-scm ];
          dependencies = with python.pkgs; [ numpy pillow ];
          env.SETUPTOOLS_SCM_PRETEND_VERSION = version;
          meta = with pkgs.lib; {
            description = "Multi-GPU Dataset Streaming";
            homepage = "https://github.com/Nerogar/mgds";
            license = licenses.mit;
          };
        };
        
        omi-model-standards = python.pkgs.buildPythonPackage rec {
          pname = "omi-model-standards";
          version = "0.1.0";
          pyproject = true;
          src = pkgs.fetchFromGitHub {
            owner = "Open-Model-Initiative";
            repo = "OMI-Model-Standards";
            rev = "f14b1da";
            sha256 = "sha256-Ai/knqvFWzyRgaDX+7i9pQC3/BlQzMywPBgeH+2DsFc=";
          };
          build-system = with python.pkgs; [ setuptools setuptools-scm ];
          dependencies = with python.pkgs; [ pyyaml torch ];
          env.SETUPTOOLS_SCM_PRETEND_VERSION = version;
          meta = with pkgs.lib; {
            description = "OMI Model Standards";
            homepage = "https://github.com/Open-Model-Initiative/OMI-Model-Standards";
            license = licenses.mit;
          };
        };
        
        # Override TensorFlow GPU to include RTX 5090 compute capability 12.0
        tensorflow-rtx5090 = (pkgs.python312Packages.tensorflow.override {
          cudaSupport = true;
        }).overrideAttrs (oldAttrs: {
          # Add RTX 5090 compute capability to build configuration
          preBuild = (oldAttrs.preBuild or "") + ''
            export TF_CUDA_COMPUTE_CAPABILITIES="8.6,8.9,9.0,12.0"
          '';
        });

        # Create Python environment with CUDA PyTorch and custom TensorFlow
        onetrainer-env = python.withPackages (ps: with ps; [
          # Build essentials
          pip
          setuptools
          wheel
          
          # Base requirements
          numpy
          opencv4
          pillow
          tqdm
          pyyaml
          huggingface-hub
          scipy
          matplotlib
          onnxruntime
          pooch
          
          # PyTorch with CUDA support (source-built)
          torch
          torchvision
          
          # ML/AI libraries
          accelerate
          safetensors
          tensorflow-rtx5090
          tensorboard
          transformers
          sentencepiece
          onnxruntime
          (diffusers.overridePythonAttrs (old: rec {
            version = "0.35.2";
            src = pkgs.fetchPypi {
              pname = "diffusers";
              version = version;
              sha256 = "1vgxmxizfi809jyvsafmnhxfwql4ia8w6ws5fbhwzpry619dbv1h";
            };
            pythonRuntimeDepsCheck = false;
          }))
          
          # UI components
          tkinter
          customtkinter
          
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
          scalene
          
          # Custom packages
          dadaptation
          prodigyopt
          schedulefree
          gguf
          mgds
          omi-model-standards
          mgds
        ]);

        onetrainer = pkgs.stdenv.mkDerivation rec {
          pname = "onetrainer";
          version = "unstable-2024-01-07";
          
          src = pkgs.fetchFromGitHub {
            owner = "Nerogar";
            repo = "OneTrainer";
            rev = "9c67bf9a4a755897acb8de1e650ff8c15776de0d";
            sha256 = "0wziasi4ajnh5brq60f41pid8bf0r0i69s232kvg0h8iw2z320mv";
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
            
            # Font support for CustomTkinter
            roboto
            fontconfig
            
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
          
          postPatch = ''
            # Fix default output_model_destination to use workspace directory
            substituteInPlace modules/util/config/TrainConfig.py \
              --replace 'data.append(("output_model_destination", "models/model.safetensors", str, False))' \
                        'data.append(("output_model_destination", os.environ.get("ONETRAINER_WORKSPACE_DIR", ".") + "/output/model.safetensors", str, False))'
            
            # Add os import to TrainConfig.py
            substituteInPlace modules/util/config/TrainConfig.py \
              --replace 'from dataclasses import dataclass' \
                        'import os\nfrom dataclasses import dataclass'
            
            # Add close button on its own row in bottom bar
            substituteInPlace modules/ui/TrainUI.py \
              --replace 'frame.grid_columnconfigure(2, weight=1)' \
                        $'frame.grid_columnconfigure(2, weight=1)\n\n        # Add close button on its own row\n        close_button = ctk.CTkButton(frame, text="Close OneTrainer", width=120, height=30, command=self.__close, fg_color="red", hover_color="darkred")\n        close_button.grid(row=1, column=0, columnspan=3, sticky="", padx=10, pady=5)'
            
            # Add close buttons to CaptionUI (Dataset Tools)
            substituteInPlace modules/ui/CaptionUI.py \
              --replace 'self.grid_columnconfigure(0, weight=1)' \
                        $'self.grid_columnconfigure(0, weight=1)\n\n        # Add close button\n        close_frame = ctk.CTkFrame(self, corner_radius=0)\n        close_frame.grid(row=99, column=0, sticky="ew", padx=10, pady=5)\n        close_button = ctk.CTkButton(close_frame, text="Close", width=80, height=30, command=self.destroy, fg_color="red", hover_color="darkred")\n        close_button.pack(pady=5)'
            
            # Add close buttons to VideoToolUI
            substituteInPlace modules/ui/VideoToolUI.py \
              --replace 'self.grid_columnconfigure(0, weight=1)' \
                        $'self.grid_columnconfigure(0, weight=1)\n\n        # Add close button\n        close_frame = ctk.CTkFrame(self, corner_radius=0)\n        close_frame.grid(row=99, column=0, sticky="ew", padx=10, pady=5)\n        close_button = ctk.CTkButton(close_frame, text="Close", width=80, height=30, command=self.destroy, fg_color="red", hover_color="darkred")\n        close_button.pack(pady=5)'
            
            # Add close buttons to ConvertModelUI
            substituteInPlace modules/ui/ConvertModelUI.py \
              --replace 'self.grid_columnconfigure(0, weight=1)' \
                        $'self.grid_columnconfigure(0, weight=1)\n\n        # Add close button\n        close_frame = ctk.CTkFrame(self, corner_radius=0)\n        close_frame.grid(row=99, column=0, sticky="ew", padx=10, pady=5)\n        close_button = ctk.CTkButton(close_frame, text="Close", width=80, height=30, command=self.destroy, fg_color="red", hover_color="darkred")\n        close_button.pack(pady=5)'
            
            # Add close buttons to SampleWindow
            substituteInPlace modules/ui/SampleWindow.py \
              --replace 'self.grid_columnconfigure(0, weight=1)' \
                        $'self.grid_columnconfigure(0, weight=1)\n\n        # Add close button\n        close_frame = ctk.CTkFrame(self, corner_radius=0)\n        close_frame.grid(row=99, column=0, sticky="ew", padx=10, pady=5)\n        close_button = ctk.CTkButton(close_frame, text="Close", width=80, height=30, command=self.destroy, fg_color="red", hover_color="darkred")\n        close_button.pack(pady=5)'
            
            # Add close buttons to ProfilingWindow
            substituteInPlace modules/ui/ProfilingWindow.py \
              --replace 'self.grid_columnconfigure(0, weight=1)' \
                        $'self.grid_columnconfigure(0, weight=1)\n\n        # Add close button\n        close_frame = ctk.CTkFrame(self, corner_radius=0)\n        close_frame.grid(row=99, column=0, sticky="ew", padx=10, pady=5)\n        close_button = ctk.CTkButton(close_frame, text="Close", width=80, height=30, command=self.withdraw, fg_color="red", hover_color="darkred")\n        close_button.pack(pady=5)'
        
            # Add close buttons to GenerateMasksWindow and fix geometry manager conflict
            substituteInPlace modules/ui/GenerateMasksWindow.py \
              --replace 'self.frame.pack(fill="both", expand=True)' \
                        $'# Add close button to frame\n        close_button = ctk.CTkButton(self.frame, text="Close", width=80, height=30, command=self.destroy, fg_color="red", hover_color="darkred")\n        close_button.grid(row=99, column=0, columnspan=2, sticky="", padx=10, pady=10)'
        
            # Add close buttons to GenerateCaptionsWindow and fix geometry manager conflict
            substituteInPlace modules/ui/GenerateCaptionsWindow.py \
              --replace 'self.frame.pack(fill="both", expand=True)' \
                        $'# Add close button to frame\n        close_button = ctk.CTkButton(self.frame, text="Close", width=80, height=30, command=self.destroy, fg_color="red", hover_color="darkred")\n        close_button.grid(row=99, column=0, columnspan=2, sticky="", padx=10, pady=10)'
            
            # Fix GenericTrainer to convert relative paths to workspace paths
            substituteInPlace modules/trainer/GenericTrainer.py \
              --replace 'save_path = self.config.output_model_destination' \
                        'save_path = self.config.output_model_destination; workspace_dir = os.environ.get("ONETRAINER_WORKSPACE_DIR", "."); save_path = os.path.join(workspace_dir, "output", os.path.basename(save_path)) if not os.path.isabs(save_path) and not save_path.startswith(workspace_dir) else save_path'
          '';
          
          installPhase = ''
            runHook preInstall
            
            # Create directories
            mkdir -p $out/{bin,share/onetrainer}
            
            # Copy all source files
            cp -r . $out/share/onetrainer/
            
            # Patch TrainConfig to read workspace_dir from environment variable
            sed -i 's|"workspace_dir", "workspace/run"|"workspace_dir", os.environ.get("ONETRAINER_WORKSPACE_DIR", "workspace/run")|' \
              $out/share/onetrainer/modules/util/config/TrainConfig.py
            sed -i 's|"cache_dir", "workspace-cache/run"|"cache_dir", os.environ.get("ONETRAINER_WORKSPACE_DIR", ".") + "/workspace-cache/run"|' \
              $out/share/onetrainer/modules/util/config/TrainConfig.py
            
            # Create wrapper scripts for different entry points
            # Copy fonts to share directory
            mkdir -p $out/share/fonts
            cp -r ${pkgs.roboto}/share/fonts/* $out/share/fonts/ || true
            
            makeWrapper ${onetrainer-env}/bin/python $out/bin/onetrainer-ui \
              --add-flags "$out/share/onetrainer/scripts/train_ui.py" \
              --set PYTHONPATH "$out/share/onetrainer:${onetrainer-env}/lib/python3.12/site-packages" \
              --set GDK_BACKEND "x11" \
              --set QT_QPA_PLATFORM "xcb" \
              --set WAYLAND_DISPLAY "" \
              --set XDG_SESSION_TYPE "x11" \
              --set DISPLAY ":0" \
              --run "echo 'DEBUG: Killing any existing TensorBoard processes...'" \
              --run "pkill -f tensorboard || true" \
              --run "echo 'DEBUG: Current directory:' \$(pwd)" \
              --run "echo 'DEBUG: Setting ONETRAINER_WORKSPACE_DIR to:' \$(pwd)" \
              --run "export ONETRAINER_WORKSPACE_DIR=\"\$(pwd)\"" \
              --run "echo 'DEBUG: ONETRAINER_WORKSPACE_DIR is now:' \$ONETRAINER_WORKSPACE_DIR" \
              --run "mkdir -p \"\$ONETRAINER_WORKSPACE_DIR/models\" \"\$ONETRAINER_WORKSPACE_DIR/output\"" \
              --run "export ONETRAINER_MODEL_OUTPUT_DIR=\"\$ONETRAINER_WORKSPACE_DIR/output\"" \
              --run "mkdir -p \"\$ONETRAINER_WORKSPACE_DIR/training_concepts\" \"\$ONETRAINER_WORKSPACE_DIR/training_samples\" \"\$ONETRAINER_WORKSPACE_DIR/training_presets\"" \
              --run "[ ! -f \"\$ONETRAINER_WORKSPACE_DIR/training_concepts/concepts.json\" ] && echo '[]' > \"\$ONETRAINER_WORKSPACE_DIR/training_concepts/concepts.json\" || true" \
              --run "[ ! -f \"\$ONETRAINER_WORKSPACE_DIR/training_samples/samples.json\" ] && echo '[]' > \"\$ONETRAINER_WORKSPACE_DIR/training_samples/samples.json\" || true" \
              --run "cp -r $out/share/onetrainer/training_presets/* \"\$ONETRAINER_WORKSPACE_DIR/training_presets/\" 2>/dev/null || true" \
              --run "echo 'DEBUG: Testing TensorFlow GPU detection...'" \
              --run "python -c \"import tensorflow as tf; print('TensorFlow version:', tf.__version__); print('GPUs Available:', len(tf.config.list_physical_devices('GPU'))); [print('GPU:', gpu) for gpu in tf.config.list_physical_devices('GPU')]\" || echo 'TensorFlow GPU test failed'" \
              --set HF_HUB_DISABLE_XET "1" \
              --set CUDA_PATH "${pkgs.cudaPackages.cudatoolkit}" \
              --set CUDA_HOME "${pkgs.cudaPackages.cudatoolkit}" \
              --set TF_FORCE_GPU_ALLOW_GROWTH "true" \
              --set TF_GPU_ALLOCATOR "cuda_malloc_async" \
              --set TF_CUDA_COMPUTE_CAPABILITIES "8.6,8.9,9.0,12.0" \
              --set CUDA_CACHE_DISABLE "1" \
              --set TF_CPP_MIN_LOG_LEVEL "1" \
              --set OPENSSL_CONF "" \
              --set OPENSSL_ENGINES "" \
              --unset SSL_CERT_FILE \
              --unset SSL_CERT_DIR \
              --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath buildInputs}:${pkgs.cudaPackages.cudatoolkit}/lib:${pkgs.cudaPackages.cudnn}/lib" \
              --set FONTCONFIG_FILE "${pkgs.fontconfig.out}/etc/fonts/fonts.conf" \
              --set FONTCONFIG_PATH "${pkgs.fontconfig.out}/etc/fonts:$out/share/fonts" \
              --run "mkdir -p \$HOME/.fonts && cp -n $out/share/fonts/truetype/Roboto-*.ttf \$HOME/.fonts/ 2>/dev/null || true && chmod 644 \$HOME/.fonts/*.ttf \$HOME/.fonts/*.otf 2>/dev/null || true" \
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
            
            # SIMPLE TEST - create a test file to see if this runs
            echo "PATCH TEST EXECUTED" > $out/patch-test.txt
            
            # Add os import to files that need it
            echo "DEBUG: Adding os imports..."
            grep -q "^import os" $out/share/onetrainer/modules/util/config/TrainConfig.py || sed -i '1i import os' $out/share/onetrainer/modules/util/config/TrainConfig.py
            grep -q "^import os" $out/share/onetrainer/modules/ui/ConceptTab.py || sed -i '1i import os' $out/share/onetrainer/modules/ui/ConceptTab.py
            grep -q "^import os" $out/share/onetrainer/modules/ui/SamplingTab.py || sed -i '1i import os' $out/share/onetrainer/modules/ui/SamplingTab.py
            grep -q "^import os" $out/share/onetrainer/modules/ui/TopBar.py || sed -i '1i import os' $out/share/onetrainer/modules/ui/TopBar.py
            grep -q "^import os" $out/share/onetrainer/modules/ui/ConfigList.py || sed -i '1i import os' $out/share/onetrainer/modules/ui/ConfigList.py
            
            # Simple direct patches
            echo "DEBUG: Patching TrainConfig.py..."
            sed -i 's|"training_concepts/concepts\.json"|os.path.join(os.environ.get("ONETRAINER_WORKSPACE_DIR", "."), "training_concepts", "concepts.json")|g' \
              $out/share/onetrainer/modules/util/config/TrainConfig.py
            sed -i 's|"training_samples/samples\.json"|os.path.join(os.environ.get("ONETRAINER_WORKSPACE_DIR", "."), "training_samples", "samples.json")|g' \
              $out/share/onetrainer/modules/util/config/TrainConfig.py
            echo "DEBUG: Patching UI files..."
            sed -i 's|config_dir="training_concepts"|config_dir=os.path.join(os.environ.get("ONETRAINER_WORKSPACE_DIR", "."), "training_concepts")|g' \
              $out/share/onetrainer/modules/ui/ConceptTab.py
            sed -i 's|config_dir="training_samples"|config_dir=os.path.join(os.environ.get("ONETRAINER_WORKSPACE_DIR", "."), "training_samples")|g' \
              $out/share/onetrainer/modules/ui/SamplingTab.py
            echo "DEBUG: Patching TopBar.py..."
            sed -i 's|"training_presets"|os.path.join(os.environ.get("ONETRAINER_WORKSPACE_DIR", "."), "training_presets")|g' \
              $out/share/onetrainer/modules/ui/TopBar.py
            # Patch __save_secrets to use workspace directory
            sed -i 's|write_json_atomic(path,|write_json_atomic(os.path.join(os.environ.get("ONETRAINER_WORKSPACE_DIR", "."), os.path.basename(path)),|g' \
              $out/share/onetrainer/modules/ui/TopBar.py
            echo "DEBUG: Patching complete"
            
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