#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32000

# Make norm bin files
# Read inputs from JSON file using Python
config_file="config.json"
neutral_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')
echo "Neutral Simulation Number: $neutral_simulation_number"

# Extract population IDs
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')

# Generate all possible pairs of population IDs and pass to make_norm_file.py
for ((i=0; i<${#pop_ids[@]}; i++)); do
    if [[ ${pop_ids[$i]} != $pop1 ]]; then
        pop2=${pop_ids[$i]}
        pair_ids="${pop1}_vs_${pop2}"

        # Assign sim_id correctly
        sim_id=$neutral_simulation_number
        
        # Pass sim_id and pair_ids to make_xpehh_bin.py
        python make_one_pop_norm_file.py "$sim_id" "$pair_ids"
        python make_xpehhbin_norm_file.py "$sim_id" "$pair_ids"

    fi
done
