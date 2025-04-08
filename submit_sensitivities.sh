#!/bin/bash

######################################
# Batch HPC Submission Script
#
# Check if the script has been made executable before running by using: 
# chmod +x submit_sensitivities.sh
#
# Usage examples:
#   ./submit_sensitivities.sh --submit-sadr
#   ./submit_sensitivities.sh --submit-saep --email=your@email.com
#   ./submit_sensitivities.sh --submit-sadr --submit-saep
#
# Flags:
#   --submit-sadr       Submit all jobs in the SADR batch
#   --submit-saep       Submit all jobs in the SAEP batch
#   --email=ADDRESS     (Optional) Email for job notifications
#
# Notes:
# - You can use both --submit-sadr and --submit-saep together
# - If --email is not provided, the submission omits the --email flag
######################################

# Define batches
SADR_BATCH=("SADR00" "SADR02" "SADR04" "SADR06" "SADR08" "SADR10" "SADR12")
SAEP_BATCH=("SAEP_low" "SAEP_base" "SAEP_high")

# Flags
submit_sadr=false
submit_saep=false
email=""

# Parse arguments
for arg in "$@"; do
  case $arg in
    --submit-sadr)
      submit_sadr=true
      ;;
    --submit-saep)
      submit_saep=true
      ;;
    --email=*)
      email="${arg#*=}"
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--submit-sadr] [--submit-saep] [--email=your@email.com]"
      exit 1
      ;;
  esac
done

# Assemble optional email flag
email_flag=""
if [ -n "$email" ]; then
  email_flag="--email=$email"
fi

# Submit SADR batch
if [ "$submit_sadr" = true ]; then
  echo "Submitting SADR batch..."
  for name in "${SADR_BATCH[@]}"; do
    echo "  Submitting $name..."
    python3 scripts/python/HPC_submission.py data/$name/scenario_parameters.csv $email_flag --submit
  done
fi

# Submit SAEP batch
if [ "$submit_saep" = true ]; then
  echo "Submitting SAEP batch..."
  for name in "${SAEP_BATCH[@]}"; do
    echo "  Submitting $name..."
    python3 scripts/python/HPC_submission.py data/$name/scenario_parameters.csv $email_flag --submit
  done
fi
