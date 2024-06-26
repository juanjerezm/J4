
    #!/bin/sh
    
    ### General options 
    ### -- specify queue -- 
    #BSUB -q man
    ### -- specify job name -- 
    #BSUB -J test
    ### -- ask for number of cores (default: 1) -- 
    #BSUB -n 16
    ### -- specify that the cores must be on the same host -- 
    #BSUB -R "span[hosts=1]"
    ### -- specify that we need X GB of memory per core/slot -- 
    #BSUB -R "rusage[mem=10GB]"
    ### -- specify that we want the job to get killed if it exceeds X GB per core/slot -- 
    #BSUB -M 10GB
    ### -- set walltime limit: hh:mm -- 
    #BSUB -W 02:00 
    ### -- set the email address -- 
    # please uncomment the following line and put in your e-mail address,
    # if you want to receive e-mail notifications on a non-default address
    ##BSUB -u jujmo@dtu.dk
    ### -- send notification at start -- 
    #BSUB -B 
    ### -- send notification at completion -- 
    #BSUB -N 
    ### -- Specify the output and error file. %J is the job-id -- 
    ### -- -o and -e mean append, -oo and -eo mean overwrite -- 
    #BSUB -oo Output_%J.out 
    #BSUB -eo Error_%J.err 

    # here follow the commands you want to execute
  
    # Define project's HPC directory, replace with your own.
    hpc_dir="/zhome/f0/5/124363/J4"
    
    # Define control flags
    name="testeo"
    policytype="taxation"
    country="DK"

    # Create directories and run model
    mkdir -p ${hpc_dir}/results/${name}/transferDir/
    gams ${hpc_dir}/scripts/gams/model --name=${name} --policytype=${policytype} --country=${country} o=${hpc_dir}/results/${name}/model.lst
    
