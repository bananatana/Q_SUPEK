#!/bin/bash

# Define the script to copy
SCRIPT_NAME="q_run_feps.sh"

# Make sure the script exists
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "Error: $SCRIPT_NAME not found in current directory."
    exit 1
fi

# Loop over rep_0* directories
for dir in rep_0*/; do
    echo "Processing $dir"

    # Copy the run script
    cp "$SCRIPT_NAME" "$dir"

    # Change to that directory
    cd "$dir" || continue

    # Submit the job
    qsub "$SCRIPT_NAME" 

    # Go back to the original directory
    cd ..
done

