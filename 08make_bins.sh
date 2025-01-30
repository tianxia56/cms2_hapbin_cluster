#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=64000

# Make norm bin files
# Read inputs from JSON file using Python
config_file="00config.json"
neutral_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')
echo "Neutral Simulation Number: $neutral_simulation_number"

# Extract population IDs
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')

# Read sim_id values from the second column of runtime/nsl.neut.runtime.csv, including the first row
sim_ids=($(awk -F, '{print $2}' runtime/nsl.neut.runtime.csv))

# Combine all sim_ids into a single string separated by commas
sim_ids_combined=$(IFS=,; echo "${sim_ids[*]}")

# Generate all possible pairs of population IDs and pass to make_norm_file.py
for ((i=0; i<${#pop_ids[@]}; i++)); do
    if [[ ${pop_ids[$i]} != $pop1 ]]; then
        pop2=${pop_ids[$i]}
        pair_ids="${pop1}_vs_${pop2}"

        # Pass all sim_ids and pop1 to the Python scripts
        python3 08one_pop_bin.py "$sim_ids_combined" "$pop1"
        python3 08xpehh_bin.py "$sim_ids_combined" "$pair_ids"
    fi
done
