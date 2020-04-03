#!/bin/bash
START=1
END=480
STEP=480
SLEEP=600 #Just over 11 Minutes (in seconds)


for i in $(seq $START $STEP $END) ; do	
    JSTART=$i
    JEND=$[ $JSTART + $STEP -1 ] 
    echo "Submitting from ${JSTART} to ${JEND}"
    sbatch --array=${JSTART}-${JEND} -p sched_mit_darwin2 --time=12:00:00 job2.sh
    sleep $SLEEP
done

# Run post-processing
cd ~/mse_AMT/
module load mit/matlab/2019a
matlab -nodesktop -nosplash -nojvm < toolbox/core/compile_AMT_subjobs.m

# Clean up
cd ~/
find . -name "matlab_crash*" -exec rm {} \;
rm ~/mse_AMT/*.out
rm ~/mse_AMT/*.err
# rm -r /nobackup1/jrcasey/*