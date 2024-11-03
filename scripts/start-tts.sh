#!/bin/bash

source /opt/open-webui/config/llaman.conf

[ -f speech.env ] && . speech.env

defaultDir=/opt/open-webui
condaSh=$defaultDir/miniconda3/etc/profile.d/conda.sh
condaEnv=$defaultDir/config/conda/opendai

source $condaSh
conda activate $condaEnv
./download_voices_tts-1.sh
python speech.py -P $opendaiPort --xtts_device none $EXTRA_ARGS $@
