#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16000

config_file="00config.json"
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')

# Read sim_id values from the second column of runtime/nsl.sel.runtime.csv, including the first row
sim_ids=($(awk -F, '{print $2}' runtime/nsl.sel.runtime.csv))

# Monitor the one_pop_stats directory for _0_1.ihs.out files and run selscan commands on them
for sim_id in "${sim_ids[@]}"; do
    Rscript 10norm_ihs.R $sim_id
done
