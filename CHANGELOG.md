# CHANGELOG.md for https://GitHub.com/Smiley-McSmiles/llaman

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

