#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16000

# Define variables
config_file="config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
simulation_serial_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["simulation_serial_number"])')

# Call make-output.R
Rscript make-output.R

# upload to gcloud
/home/tx56/google-cloud-sdk/bin/gsutil cp output/${demographic_model}_batch${simulation_serial_number}_cms_stats_all_*.zip gs://fc-97de97ff-f4ee-414a-bf2d-a5f045b20a79/yale_cluster_sim_stats/${demographic_model%.par}
