# CHANGELOG.md for https://GitHub.com/Smiley-McSmiles/llaman

# LLaMan v0.2.2
## Fixes
- Fixed `llaman -u` not changing port to customized port number
- Fixed `llaman -cp` not changing port once the port has already been changed

# LLaMan v0.2.1
## Fixes
- Fixed updater failing due to wrong git clone directory

# LLaMan v0.2.0
## Changes
- Backup now completely backups /opt/open-webui and Ollama for easy import on another machine.
  - Meaning backups will now be rather large!

## Fixes
- Fixed language in setup.sh
- Fixed some langauge in llaman

## Additions
- Added OpendAI-Speech integration
  - _Default port is `8000`_
- Added `llaman -cps` (**C**hange **P**ort **S**peech)
  - _Presents a prompt to enter a new port for OpendAI-Speech_
- `sudo ./setup.sh` now has a `-I` option. Supply path to **I**mport a llaman.tar backup.
  - _example:_ `sudo ./setup.sh -I /path/to/llaman-backup.tar`

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

