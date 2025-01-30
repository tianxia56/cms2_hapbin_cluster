#!/bin/bash
#SBATCH --partition=week
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8000

# Read arguments
pair_id=$1

# Read sim_id values from the second column of runtime/xpehh.sel.map.runtime.csv, including the first row
sim_ids=($(awk -F, '{print $2}' runtime/xpehh.sel.map.runtime.csv))

# Run R scripts for each sim_id
for sim_id in "${sim_ids[@]}"; do
    Rscript 10norm_xpehhbin.R $sim_id $pair_id
    Rscript 10max_xpehh.R $sim_id $pair_id
done
