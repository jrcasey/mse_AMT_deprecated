# Connecting to the MIT server
ssh -F $HOME/eofe-cluster/linux/config eofe7.mit.edu

# Submitting a batch job array using SLURM
## For a specified interval (e.g., iterations 15-29)
sbatch --array=15-29 -p sched_mit_darwin2 --time=12:00:00 job2.sh

## Looping through intervals
sh Job_loop.sh

#Downloading data from MIT server locally
## Copying a single file to a local directory
scp -i /Users/jrcasey/eofe-cluster/linux/eofe-key jrcasey@eofe7.mit.edu:~/mse_AMT/data/output/FullSolution.mat ~/Documents/MATLAB/CBIOMES/Data/Environmental_Data/Cruises/AMT13/

## Copying all results files to a local directory
scp -i /Users/jrcasey/eofe-cluster/linux/eofe-key -r jrcasey@eofe7.mit.edu:/nobackup1/jrcasey/. ~/Documents/MATLAB/CBIOMES/Data/Environmental_Data/Cruises/AMT13/mse_Results/

# Clean up scratch and home dir
rm -r /nobackup1/jrcasey/*

### Clean up mse (while logged in)
rm ~/mse_AMT/*.out
rm ~/mse_AMT/*.err
find . -name "matlab_crash*" -exec rm {} \;

#### How many files?
ls -f . | wc -l
