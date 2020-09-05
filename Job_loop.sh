#!/bin/bash
START=1
END=13800
STEP=460
SLEEP=600 #Just over 11 Minutes (in seconds)


for i in $(seq $START $STEP $END) ; do	
    JSTART=$i
    JEND=$[ $JSTART + $STEP -1 ] 
    echo "Submitting from ${JSTART} to ${JEND}"
    sbatch --array=${JSTART}-${JEND} -p sched_mit_darwin2 --time=12:00:00 job2.sh
	sleep $SLEEP
done
