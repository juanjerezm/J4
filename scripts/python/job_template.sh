
    #!/bin/sh
    
    #BSUB -J ${project}_${scenario}
    #BSUB -q man

    #BSUB -n 8
    #BSUB -R "span[hosts=1]"
    #BSUB -R "rusage[mem=10GB]"
    #BSUB -M 10GB
    #BSUB -W 02:00 

    #BSUB -B 
    #BSUB -N 

    #BSUB -oo ${base_dir}/results/${project}/${scenario}/Output_%J.out 
    #BSUB -eo ${base_dir}/results/${project}/${scenario}/Error_%J.err 
        
    ### Get paths to GAMS 37
    export PATH=/appl/gams/37.1.0:$PATH
    export LD_LIBRARY_PATH=/appl/gams/37.1.0:$LD_LIBRARY_PATH

    gams ${base_dir}/scripts/gams/model --project=${project} --scenario=${scenario} --country=${country} --policytype=${policytype} o=${base_dir}/results/${project}/${scenario}/model.lst
    
