#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16000

# Read inputs from JSON file using Python
config_file="config.json"
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')

# Extract population IDs
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')

# Generate all possible pairs of population IDs and pass to norm_xpehh.R
for ((i=0; i<${#pop_ids[@]}; i++)); do
    if [[ ${pop_ids[$i]} != $pop1 ]]; then
        pop2=${pop_ids[$i]}
        pair_id="${pop1}_vs_${pop2}"

        for ((sim_id=0; sim_id<=selected_simulation_number; sim_id++)); do
            Rscript norm_xpehhbin.R $sim_id $pair_id
            Rscript make_max_xpehh.R $sim_id $pair_id
        done
    fi
done
