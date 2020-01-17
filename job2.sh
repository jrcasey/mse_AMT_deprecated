#!/bin/bash
#
#SBATCH -J cnhjarray # A single job name for the array
#SBATCH -o cnhjarray_%A_%a.out # Standard output
#SBATCH -e cnhjarray_%A_%a.err # Standard error

module load mit/matlab/2019a
echo ${SLURM_ARRAY_TASK_ID}

cd /nobackup1/cnh

matlab -nodesktop -nosplash -nojvm < MESO_SCOPE_Wrapper.m
sleep 3
