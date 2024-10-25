#!/bin/bash

defaultDir=/opt/open-webui
condaSh=/$defaultDir/miniconda3/etc/profile.d/conda.sh
condaEnv=$defaultDir/config/conda/open-webui
openWebuiStart=$defaultDir/open-webui/backend/start.sh

source $condaSh
conda activate $condaEnv
$openWebuiStart
