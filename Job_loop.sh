#!/bin/bash
START=1
END=19584
STEP=408
SLEEP=700 #Just over 11 Minutes (in seconds)

for i in $(seq $START $END $STEP) ; do
    JSTART=$i
    JEND=$[ $JSTART + $STEP ] 
    echo "Submitting with ${JSTART} and ${JEND}"
    sbatch --array=${JSTART}-${JEND} -p sched_mit_darwin2 --time=12:00:00 job2.sh
    sleep $SLEEP
done