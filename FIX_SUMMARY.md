# OneTrainer Config Directory Fix

## Problem
When running OneTrainer via the flake with:
```bash
cd ~/onetrainer-workspace && nix run --no-eval-cache --refresh github:celesrenata/OneTrainer-flake
```

The application failed with:
```
Failed to load config from training_concepts/concepts.json: [Errno 2] No such file or directory: 'training_concepts/concepts.json'
Failed to load config from training_samples/samples.json: [Errno 2] No such file or directory: 'training_samples/samples.json'
```

Even though these files existed in `/home/celes/onetrainer-workspace/training_concepts/concepts.json` and `/home/celes/onetrainer-workspace/training_samples/samples.json`.

## Root Cause
The issue was in `modules/ui/ConfigList.py` in the `__load_available_config_names()` method. 

When `ConfigList` was instantiated with:
- `config_dir="training_concepts"` (from ConceptTab.py)
- `config_dir="training_samples"` (from SamplingTab.py)

The code was using these **relative paths directly** without prepending the workspace directory:

```python
def __load_available_config_names(self):
    if os.path.isdir(self.config_dir):  # ← Uses relative path!
        for path in os.listdir(self.config_dir):  # ← Uses relative path!
```

This meant it was looking for `training_concepts/` relative to where the Python process was running (inside the nix store), not in the user's workspace.

## The Fix
Added a critical patch in `flake.nix` that modifies `ConfigList.py` after the source is copied:

```bash
# CRITICAL FIX: Patch ConfigList.py to prepend workspace dir to config_dir if it's relative
# This ensures that self.config_dir is an absolute path pointing to the workspace
sed -i '/self\.config_dir = config_dir/a\        if self.from_external_file and config_dir and not os.path.isabs(config_dir):\n            workspace_dir = os.environ.get("ONETRAINER_WORKSPACE_DIR", ".")\n            self.config_dir = os.path.join(workspace_dir, config_dir)' \
  $out/share/onetrainer/modules/ui/ConfigList.py
```

This patch adds code immediately after `self.config_dir = config_dir` to check if:
1. We're loading from an external file (`self.from_external_file`)
2. A config_dir was provided
3. The path is not already absolute

If all conditions are met, it prepends `ONETRAINER_WORKSPACE_DIR` to create an absolute path.

## Technical Details

### Before the fix:
```python
self.config_dir = config_dir  # e.g., "training_concepts"
# Later...
if os.path.isdir(self.config_dir):  # Looks for "training_concepts" relative to CWD
```

### After the fix:
```python
self.config_dir = config_dir  # e.g., "training_concepts"
if self.from_external_file and config_dir and not os.path.isabs(config_dir):
    workspace_dir = os.environ.get("ONETRAINER_WORKSPACE_DIR", ".")
    self.config_dir = os.path.join(workspace_dir, config_dir)
# Now self.config_dir = "/home/celes/onetrainer-workspace/training_concepts"
# Later...
if os.path.isdir(self.config_dir):  # Looks in the correct absolute path!
```

## Testing
To test the fix:

1. Clear the nix cache for this flake:
```bash
nix store delete /nix/store/*onetrainer* 2>/dev/null || true
```

2. Navigate to your workspace:
```bash
cd ~/onetrainer-workspace
```

3. Run OneTrainer with the updated flake:
```bash
nix run --no-eval-cache --refresh github:celesrenata/OneTrainer-flake
```

4. The application should now load without the config file errors.

## Files Modified
- `flake.nix`: Added the ConfigList.py patch and os import

## Commit
```
commit d84a21b
Fix config directory path resolution for training_concepts and training_samples

- Added import os to ConfigList.py
- Added critical patch to prepend ONETRAINER_WORKSPACE_DIR to relative config_dir paths
- This ensures ConfigList.__load_available_config_names() looks in the correct workspace directory
- Fixes 'No such file or directory' errors for concepts.json and samples.json