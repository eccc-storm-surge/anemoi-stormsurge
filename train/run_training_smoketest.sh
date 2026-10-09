#!/bin/bash
#PBS -N stormsurge_train_smoketest
#PBS -l select=1:ncpus=48:ngpus=2:ompthreads=2:vntype=gpu:mem=200gb
#PBS -l walltime=3:00:00
#PBS -W umask=0022
#PBS -o /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/train/train_logs/stormsurge_train_smoketest_NaNzero_moreEpoches.out
#PBS -e /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/train/train_logs/stormsurge_train_smoketest_NaNzero_moreEpoches.err


. r.load.dot /fs/ssm/eccc/cmd/cmds/apps/pixi/202607/00/pixi_0.75.0_all
set -euo pipefail

ulimit -v unlimited
export HYDRA_FULL_ERROR=1
export MLFLOW_ALLOW_FILE_STORE=true
export PATH=/opt/pbs/bin:${PATH}

cd /home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge/train
pixi run --offline anemoi-training train --config-name=stormesurge_train_0929_suc_smoketest_batch_100.yaml
