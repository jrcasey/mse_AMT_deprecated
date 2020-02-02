#Downloading data from MIT server
## Copying a single file to a local directory
scp -i /Users/jrcasey/eofe-cluster/linux/eofe-key jrcasey@eofe7.mit.edu:~/mse/data/output/FullSolution.mat ~/Documents/MATLAB/CBIOMES/Data/Environmental_Data/Cruises/MESO-SCOPE/

## Copying all results files to a local directory
scp -i /Users/jrcasey/eofe-cluster/linux/eofe-key -r jrcasey@eofe7.mit.edu:/nobackup1/jrcasey/. ~/Documents/MATLAB/CBIOMES/Data/Environmental_Data/Cruises/MESO-SCOPE/mse_Results/

### Clean up the scratch (while logged in)
rm -r /nobackup1/jrcasey/*
#### How many files?
ls -f . | wc -l
### Clean up mse (while logged in)
rm ~/mse/*.out
rm ~/mse/*.err
find . -name "matlab_crash*" -exec rm {} \;

# Connecting to the MIT server
ssh -F $HOME/eofe-cluster/linux/config eofe7.mit.edu

# Submitting a batch job array using SLURM
sbatch --array=1-19584 -p sched_mit_darwin2 --time=12:00:00 job2.sh