#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16000

# Define variables
config_file="00config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
simulation_serial_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["simulation_serial_number"])')
upload_output=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["upload_output"])')
upload_command=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["upload_command"])')

# Call make-output.R
Rscript 11output.R

# Define the destination folder
destination_folder="gs://fc-97de97ff-f4ee-414a-bf2d-a5f045b20a79/yale_cluster_sim_stats/${demographic_model%.par}"

# Check if upload_output is true and execute the upload command
if [ "$upload_output" = "true" ]; then
    eval $upload_command
fi
