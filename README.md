> LLaMan v0.2.0 - An Ollama and Open-WebUI manager written in BASH

> Tested on Fedora 40/41 | Ubuntu 24.04

> Should work on Any Debian, Arch, or RHEL Based Distribution **with SystemD**

# Description

LLaMan is a lightweight BASH CLI (Command Line Interface) tool for installing and managing Ollama, Open-WebUI, and OpendAI-Speech.

# Getting Started

```sh
git clone https://github.com/Smiley-McSmiles/llaman
cd llaman
chmod ug+x setup.sh
sudo ./setup.sh
# sudo ./setup.sh -I /path/to/llaman-backup.tar
cd ~/
```

# Features

* **Setup** - Install Ollama, Open-WebUI, and OpendAI-Speech at once
* **Update** - Downloads and updates to the latest Ollama, Open-WebUI, OpendAI-Speech versions
* **Disable** - Disable Ollama, Open-WebUI, and Opend-Speech
* **Enable** - Enable Ollama, Open-WebUI, and Opend-Speech
* **Start** - Start Ollama, Open-WebUI, and Opend-Speech
* **Stop** - Stop Ollama, Open-WebUI, and Opend-Speech
* **Restart** - Restart Ollama, Open-WebUI, and Opend-Speech
* **Status** - Get status of Ollama, Open-WebUI, and Opend-Speech
* **Download** - Download a .gguf file from Hugging Face via URL
* **Remove** - Remove a model from Ollama
* **Remove GGUF** - Remove a downloaded .gguf model
* **Install** - Install a downloaded .gguf model
* **Change Port** - Change the default port for Open-WebUI or OpendAI-Speech
* **Backup** - Input a directroy to output a backup archive
* **Backup Utility** - Start the Backup Utility to set up automatic backups
* **Import** - Import a .tar file to pick up where you left off on another system
  - _Use `sudo ./setup.sh /path/to/llaman-backup.tar` to import/restore a backup_
* **Get Version** - Get the current installed version of LLaMan, Ollama, and Open-WebUI
* **View Logs** - Select from a list of logs to view
* **Uninstall** - Uninstalls LLaMan, Ollama, Open-WebUI, and Opend-AI-Speech completely

# Usage
```
llaman [PARAMETER]

PARAMETERS:
-b,    --backup             Backup Open-WebUI users and settings
-bu,   --backup-utility     Start the backup utility
-i,    --import             Import Open-WebUI archive
-e,    --enable             Enable Ollama and Open-WebUI
-d,    --disable            Disable Ollama and Open-WebUI
-s,    --start              Start Ollama and Open-WebUI
-S,    --stop               Stop Ollama and Open-WebUI
-r,    --restart            Restart Ollama and Open-WebUI
-t,    --status             Get status of ollama.service and open-webui.service.
-I,    --install            Install a downloaded .gguf model
-R,    --remove             Remove model from Ollama
-rg,   --remove-gguf        Remove downloaded .gguf model
-D,    --download           Download .gguf file from https://huggingface.co
-u,    --update             Update Ollama and Open-Webui
-cp,   --change-port        Change the Open-WebUI port
-cps,  --change-port-speech ChangeSpeechPort
-v,    --version            Get LLaMan, Ollama, and Open-Webui version
-vl,   --view-logs          View LLaMan logs
-h,    --help               Display this help menu
-X,    --uninstall          Uninstall LLaMan, Ollama, and Open-Webui
Example: sudo llaman -e
```

### License
   This project is licensed under the [GPL V3.0 License](https://github.com/Smiley-McSmiles/llaman/blob/main/LICENSE).

