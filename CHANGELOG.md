# CHANGELOG.md for https://GitHub.com/Smiley-McSmiles/llaman

# LLaMan v0.1.9
## Fixes
- Removed dead line in the setup script.
- fixed issue with a conda command.

# LLaMan v0.1.8
## Changes
- Changed Conda install to miniconda3 via wget instead of the package manager.

## Additions
- `sudo llaman -ba` now properly backs up miniconda3 and the new start.sh

# LLaMan v0.1.7
## Additions
- Added function `llaman -cp/--change-port`

## Changes
- updated llaman-functions with better `SetVar` function.
- LLaMan now uses Conda with Python 3.11 for stability

## Fixes
- Fixed `jellyman` to `LLaMan` in the man page

# LLaMan v0.1.6
## Additions
- Added a running log of Open-WebUI to `/opt/open-webui/log/open-webui.log` (This will apply on next Open-WebUI version update)
- Added `llaman -rm --remove-gguf` function. This deletes a selected .gguf from your downloads.
- Added modelfiles: deepseekv2 and llama3_2_instruct.

## Changes
- Changed llaman.log max log lines to 5000 from 1000.

# LLaMan v0.1.5
## Fixes
- Fixed the `HasSudo` checker.
- Fixed `llaman -u` Ollama checker not checking versions properly. Resulting in downloading the latest version when the system already has that version.

