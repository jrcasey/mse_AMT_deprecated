#Downloading data from MIT server
## Copying a single file to a local directory
scp -i /Users/jrcasey/eofe-cluster/linux/eofe-key jrcasey@eofe7.mit.edu:/nfs/cnhlab001/cnh/projects/jrcasey/mse/data/output/Solution_1.mat ~/Documents/MATLAB/GitHub/mse/data/output/

## Copying a directory to a local directory


# Connecting to the MIT server
ssh -F $HOME/eofe-cluster/linux/config eofe7.mit.edu

# Submitting a batch job array using SLURM
cd /nfs/cnhlab001/cnh/projects/jrcasey/mse/

sbatch --array=1-20 -p sched_mit_darwin2  --time=12:00:00 job2.sh