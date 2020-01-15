** foo.slurm **
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

** foo.m **
job_array_idx=getenv('SLURM_ARRAY_TASK_ID');
jai=str2num(job_array_idx)
sprintf('%d', jai)



sbatch --array=1-200 -p sched_mit_darwin2 --exclusive -N 2
--time=12:00:00 foo.slurm
