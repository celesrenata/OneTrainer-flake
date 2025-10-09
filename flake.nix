{
  description = "OneTrainer - A one-stop solution for all your stable diffusion training needs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        python = pkgs.python312;
        
        onetrainer-env = python.withPackages (ps: with ps; [
          # Base requirements
          numpy
          opencv4
          pillow
          tqdm
          pyyaml
          huggingface-hub
          scipy
          matplotlib
          
          # PyTorch
          torch-bin
          torchvision-bin
          
          # Diffusion models
          transformers
          safetensors
          tensorboard
          
          # UI
          tkinter
          
          # Utilities
          psutil
          requests
          
          # Development
          pip
          setuptools
          wheel
        ]);

        onetrainer = pkgs.stdenv.mkDerivation rec {
          pname = "onetrainer";
          version = "unstable";
          
          src = pkgs.fetchFromGitHub {
            owner = "Nerogar";
            repo = "OneTrainer";
            rev = "master";
            sha256 = "sha256-v7wSXF+NKQ1L/JuXpwJEMGalgcOhBKZs2tNqRyrGpFI=";
          };
          
          nativeBuildInputs = with pkgs; [
            onetrainer-env
          ];
          
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
          ];
          
          installPhase = ''
            mkdir -p $out/share/onetrainer
            cp -r . $out/share/onetrainer/
            
            mkdir -p $out/bin
            cat > $out/bin/onetrainer << EOF
#!/bin/sh
cd $out/share/onetrainer
exec ${onetrainer-env}/bin/python OneTrainer.py "\$@"
EOF
            chmod +x $out/bin/onetrainer
          '';
          
          meta = with pkgs.lib; {
            description = "A one-stop solution for all your stable diffusion training needs";
            homepage = "https://github.com/Nerogar/OneTrainer";
            license = licenses.agpl3Only;
            platforms = platforms.linux;
          };
        };

      in {
        packages.default = onetrainer;
        packages.onetrainer = onetrainer;
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            onetrainer-env
            git
            curl
            wget
          ];
          
          shellHook = ''
            echo "OneTrainer development environment"
            echo "Run 'python OneTrainer.py' to start"
          '';
        };
        
        apps.default = {
          type = "app";
          program = "${onetrainer}/bin/onetrainer";
        };
      });
}
