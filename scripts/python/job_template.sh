
    #!/bin/sh
    
    ### -- job name --
    #BSUB -J ${project}_${scenario}
    
    ### -- specify queue --
    #BSUB -q ${queue}

    ### -- number of CPU cores requested -- 
    #BSUB -n ${cores}

    ### -- Ensure all cores are on the same host --
    #BSUB -R "span[hosts=1]"

    ### -- memory reserved per core for scheduling --
    #BSUB -R "rusage[mem=${memory}GB]"

    ### -- Hard memory limit per core (job is killed if exceeded) --
    #BSUB -M ${memory}GB

    ### -- walltime limit (hh:mm) --
    #BSUB -W ${walltime}

    ### -- email notification on job start/end --
    #BSUB -B
    #BSUB -N
    ### -- optional: non-default email address --
    #BSUB -u ${email}

    ### -- log files for std output and error --
    #BSUB -oo ${base_dir}/results/${project}/${scenario}/Output_%J.out
    #BSUB -eo ${base_dir}/results/${project}/${scenario}/Error_%J.err
        
    ### -- load GAMS 37 into environment --
    export PATH=/appl/gams/37.1.0:$PATH

    ### Not sure if this is needed, but I will leave it here for now
    # export LD_LIBRARY_PATH=/appl/gams/37.1.0:$LD_LIBRARY_PATH

    ### -- run GAMS model --
    gams ${base_dir}/run.gms \
        --project=${project} \
        --scenario=${scenario} \
        ${flags} \
        o=${base_dir}/results/${project}/${scenario}/run.lst
