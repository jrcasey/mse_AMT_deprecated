#!/bin/bash
#
#SBATCH -J jrcaseyjarray # A single job name for the array
#SBATCH -o jrcaseyjarray_%A_%a.out # Standard output
#SBATCH -e jrcaseyjarray_%A_%a.err # Standard error

module load mit/matlab/2019a
echo ${SLURM_ARRAY_TASK_ID}

cd /home/jrcasey/mse_AMT/

matlab -nodesktop -nosplash -nojvm < toolbox/wrappers/AMT_Wrapper.m
sleep 3
