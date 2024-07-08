#!/bin/bash

# ===== Control Flags and Variables =====
# Define HPC directory
base_dir="/zhome/f0/5/124363/J4-test"

# Run-specific control flags
project="defproj"
scenario="defscn"
policytype="support"
country="DK"

# Create output directory
output_dir="${base_dir}/results/${project}/${scenario}"
mkdir -p ${output_dir}

# LSF Job parameters
queue="man"
cores=16
memory="10GB"
walltime="02:00"

# ===== Create Temporary Script =====
temp_script=$(mktemp)

# ===== Write Job Script =====
cat > "$temp_script" << EOF
    #!/bin/sh

    ### General options 
    ### -- specify queue -- 
    #BSUB -q ${queue}
    ### -- specify job name -- 
    #BSUB -J ${project}_${scenario}
    ### -- ask for number of cores (default: 1) -- 
    #BSUB -n ${cores}
    ### -- specify that the cores must be on the same host -- 
    #BSUB -R "span[hosts=1]"
    ### -- specify that we need X GB of memory per core/slot -- 
    #BSUB -R "rusage[mem=${memory}]"
    ### -- specify that we want the job to get killed if it exceeds X GB per core/slot -- 
    #BSUB -M ${memory}
    ### -- set walltime limit: hh:mm -- 
    #BSUB -W ${walltime}
    ### -- set the email address -- 
    ### -- send notification at start -- 
    #BSUB -B 
    ### -- send notification at completion -- 
    #BSUB -N 
    ### -- Specify the output and error file. %J is the job-id -- 
    ### -- -o and -e mean append, -oo and -eo mean overwrite -- 
    #BSUB -oo ${output_dir}/Output_%J.out
    #BSUB -eo ${output_dir}/Error_%J.err

    # Run GAMS model
    gams ${base_dir}/scripts/gams/model --project=${project} --scenario=${scenario} --policytype=${policytype} --country=${country} o=${output_dir}/model.lst
EOF

# ===== Submit Job =====
bsub < "$temp_script"

# ===== Clean Up =====
rm "$temp_script"
