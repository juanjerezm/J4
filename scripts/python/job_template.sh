
    #!/bin/sh
    
    #BSUB -J ${name}
    #BSUB -q man

    #BSUB -n 16
    #BSUB -R "span[hosts=1]"
    #BSUB -R "rusage[mem=10GB]"
    #BSUB -M 10GB
    #BSUB -W 01:00 

    #BSUB -B 
    #BSUB -N 

    #BSUB -oo Output_%J.out 
    #BSUB -eo Error_%J.err 
    
    gams ${hpc_dir}/scripts/gams/model --name=${name} --country=${country} --policytype=${policytype} o=${hpc_dir}/results/${name}/model.lst
    
