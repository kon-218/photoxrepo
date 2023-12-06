#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: ./slurm_run.sh orca_path input_dir output_dir job_name"
    exit 1
fi

echo $(pwd)

# Assign each argument to a variable
orca_path=$1
input_dir=$2
output_dir=$3
job_name=$4


#SBATCH -J $job_name   # Job name
#SBATCH -o orca_calculations_%j.out   # Output file
#SBATCH -e orca_calculations_%j.err   # Error file
#SBATCH -p LOCALQ   # Partition/queue name
#SBATCH -n 1   # Number of tasks (adjust based on your needs)
#SBATCH --cpus-per-task=1   # Number of CPU cores per task
#SBATCH --mem=2G   # Memory per CPU core

# Change to the input directory
cd "$input_dir" || exit

# Loop over ORCA input files and submit jobs
for input_file in *.com; do
    #echo $input_file
    #echo "$orca_path" "$input_dir$input_file"
    # Extract the file name without extension
    base_name=$(basename "$input_file" .com)

    # Run ORCA job for each input file
    "$orca_path" $input_dir$input_file > "$output_dir${base_name}_output.log" &
done

# Wait for all ORCA jobs to finish
wait

echo "All ORCA jobs have completed."