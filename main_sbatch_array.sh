#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4000

# Create output directory if it doesn't exist
mkdir -p output

# Function to record job runtime
record_runtime() {
    job_name=$1
    start_time=$2
    end_time=$3
    runtime=$((end_time - start_time))
    runtime_formatted=$(printf '%02d:%02d:%02d' $((runtime/3600)) $((runtime%3600/60)) $((runtime%60)))
    echo "Job name: $job_name, runtime: $runtime_formatted" >> output/totalruntime.txt
}

# Function to wait for jobs to complete
wait_for_jobs() {
    job_ids=("$@")
    for job_id in "${job_ids[@]}"; do
        while : ; do
            job_status=$(squeue --job "$job_id" --noheader --format "%T" 2>/dev/null)
            if [[ -z "$job_status" || "$job_status" == "COMPLETED" || "$job_status" == "FAILED" || "$job_status" == "CANCELLED" ]]; then
                break
            fi
            sleep 10
        done
    done
}

# Record the start time of the entire process
start_time_total=$(date +%s)

job_ids=()

# Submit tasks for selected simulations
start_time=$(date +%s)
job_id=$(sbatch --parsable run_cosi2_even_sel.sh)
job_ids+=($job_id)
record_runtime "run_cosi2_even_sel.sh" $start_time $(date +%s)

start_time=$(date +%s)
job_id=$(sbatch --parsable run_cosi2_odd_sel.sh)
job_ids+=($job_id)
record_runtime "run_cosi2_odd_sel.sh" $start_time $(date +%s)

# Submit a single task for neutral simulations
start_time=$(date +%s)
job_id=$(sbatch --parsable run_cosi2_neut.sh)
job_ids+=($job_id)
record_runtime "run_cosi2_neut.sh" $start_time $(date +%s)

# Submit the one pop stats task (ihs, nsl, ihh12) for both sel and neut separately, optimize runtime
start_time=$(date +%s)
job_id=$(sbatch --parsable run_ihs_sel.sh)
job_ids+=($job_id)
record_runtime "run_ihs_sel.sh" $start_time $(date +%s)

start_time=$(date +%s)
job_id=$(sbatch --parsable run_ihs_neut.sh)
job_ids+=($job_id)
record_runtime "run_ihs_neut.sh" $start_time $(date +%s)

# Combine nsl and ihh12 into one job
start_time=$(date +%s)
job_id=$(sbatch --parsable run_nsl_ihh12.sh)
job_ids+=($job_id)
record_runtime "run_nsl_ihh12.sh" $start_time $(date +%s)

# Submit the run_isafe.sh task to run in parallel (isafe, DAF) for selected sims
start_time=$(date +%s)
job_id=$(sbatch --parsable run_isafe.sh)
job_ids+=($job_id)
record_runtime "run_isafe.sh" $start_time $(date +%s)

# Submit hapbin xpehh sel and neut
start_time=$(date +%s)
job_id=$(sbatch --parsable hbin_sel.sh)
job_ids+=($job_id)
record_runtime "hbin_sel.sh" $start_time $(date +%s)

start_time=$(date +%s)
job_id=$(sbatch --parsable hbin_neut.sh)
job_ids+=($job_id)
record_runtime "hbin_neut.sh" $start_time $(date +%s)

# Wait for all initial jobs to complete
wait_for_jobs "${job_ids[@]}"

# Submit the final task to normalize, collate stats and format results
start_time=$(date +%s)
final_job_id=$(sbatch --parsable make_norm_file.sh)
record_runtime "make_norm_file.sh" $start_time $(date +%s)
echo "Final job submitted with ID: $final_job_id"

# Wait for make_norm_file.sh to complete
wait_for_jobs "$final_job_id"

# Submit fst deldaf.sh task
start_time=$(date +%s)
fst_job_id=$(sbatch --parsable --export=ALL,pop_ids="${pop_ids[*]}" run_fst_deldaf.sh)
record_runtime "run_fst_deldaf.sh" $start_time $(date +%s)

# Submit parallel normalization jobs after make_norm_file.sh
norm_jobs=()
start_time=$(date +%s)
norm_jobs+=($(sbatch --parsable norm_ihs.sh))
norm_jobs+=($(sbatch --parsable norm_nsl.sh))
norm_jobs+=($(sbatch --parsable norm_ihh12.sh))
norm_jobs+=($(sbatch --parsable norm_delihh.sh))
norm_jobs+=($(sbatch --parsable norm_xpehhbin.sh))
record_runtime "norm_one_pop_stats.sh" $start_time $(date +%s)

# Wait for all normalization jobs to complete
wait_for_jobs "${norm_jobs[@]}"

# Submit final_output.sh after all normalization jobs are done
start_time=$(date +%s)
final_output_job_id=$(sbatch --parsable final_output.sh)
record_runtime "final_output.sh" $start_time $(date +%s)
echo "final_output.sh job submitted with ID: $final_output_job_id"

# Record the total runtime
end_time_total=$(date +%s)
total_runtime=$((end_time_total - start_time_total))
total_runtime_formatted=$(printf '%02d:%02d:%02d' $((total_runtime/3600)) $((total_runtime%3600/60)) $((total_runtime%60)))
echo "Total runtime: model $demographic_model serial number $simulation_serial_number $total_runtime_formatted, Date: $(date)" >> output/totalruntime.txt

# Run clean.sh to clear temp files
