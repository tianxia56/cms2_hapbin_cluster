#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16000

# Define variables
config_file="00config.json"
upload_output=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["upload_output"])')
upload_command_template=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["upload_command_template"])')
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
simulation_serial_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["simulation_serial_number"])')
demographic_model_base=$(basename "$demographic_model" .par)

# Generate the upload command with dynamic file names
upload_command=$(echo "$upload_command_template" | sed "s/{demographic_model}/$demographic_model/" | sed "s/{simulation_serial_number}/$simulation_serial_number/" | sed "s/{demographic_model_base}/$demographic_model_base/")

# Convert upload_output to lowercase
upload_output=$(echo "$upload_output" | tr '[:upper:]' '[:lower:]')

# Call make-output.R
Rscript 11output.R

# Check if upload_output is true and execute the upload command
if [ "$upload_output" = "true" ]; then
    eval $upload_command
fi
