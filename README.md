> LLaMan v0.1.1 - A Ollama and Open-WebUI manager written in BASH

> Tested on Fedora 40

> Should work on Any Debian, Arch, or RHEL Based Distribution **with SystemD**

# Description

LLaMan is a lightweight BASH CLI (Command Line Interface) tool for installing and managing Ollama and Open-WebUI.

# Getting Started

```sh
git clone https://github.com/Smiley-McSmiles/llaman
cd llaman
chmod ug+x setup.sh
sudo ./setup.sh
cd ~/
```

# Features

* **Setup** - Sets up the initial install.
* **Update** - Downloads and updates to the latest Ollama or Open-WebUI version
* **Disable** - Disable ollama.service and open-webui.service
* **Enable** - Enable ollama.service and open-webui.service
* **Start** - Start ollama.service and open-webui.service
* **Stop** - Stop ollama.service and open-webui.service
* **Restart** - Restart ollama.service and open-webui.service
* **Status** - Get status of ollama.service and open-webui.service
* **Download** - Download a .gguf file from Hugging Face via URL
* **Remove** - Remove a model from Ollama
* **Install** - Install a downloaded .gguf model.
* **Backup** - Input a directroy to output a backup archive.
* **Import** - Import a .tar file to pick up where you left off on another system.
* **Get Version** - Get the current installed version of LLaMan, Ollama, and Open-WebUI.
* **View Logs** - Select from a list of logs to view.
* **Uninstall** - Uninstalls LLaMan, Ollama, and Open-WebUI completely

# Usage

llaman [PARAMETER]

PARAMETERS:
-b = Backup Open-WebUI users and settings
-e = Enable Ollama and Open-WebUI
-d = Disable Ollama and Open-WebUI
-s = Start Ollama and Open-WebUI
-S = Stop Ollama and Open-WebUI
-r = Restart Ollama and Open-WebUI
-i = Install a downloaded .gguf model
-r = remove model from Ollama
-D = download .gguf file from https://huggingface.co
-u = update Ollama and Open-Webui
-v = get LLaMan, Ollama, and Open-Webui version
-h = display this help menu
-X = Uninstall LLaMan, Ollama, and Open-Webui
"Example: sudo llaman -d

### License

   This project is licensed under the [GPL V3.0 License](https://github.com/Smiley-McSmiles/llaman/blob/main/LICENSE).

