
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

    #BSUB -oo ${base_dir}/results/${name}/Output_%J.out 
    #BSUB -eo ${base_dir}/results/${name}/Error_%J.err 
    
    gams ${base_dir}/scripts/gams/model --name=${name} --country=${country} --policytype=${policytype} o=${base_dir}/results/${name}/model.lst
    
