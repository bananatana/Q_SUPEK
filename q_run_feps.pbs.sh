#!/bin/bash
#PBS -q cpu
#PBS -l select=32:mem=500mb

cd ${PBS_O_WORKDIR}
module load scientific/q6/23.11

# ==== USER VARIABLES ====
NUM_EQUIL=2
# ========================

# Run equilibration steps
for step in $(seq -f "%03g" 0 $((NUM_EQUIL - 1))); do
    inp_file=$(ls equil_${step}_*.inp)
    echo "Running equilibration $inp_file..."
    mpirun -hostfile ${PBS_NODEFILE} Qdyn6p "$inp_file" > "${inp_file%.inp}.log"
done

# Run FEP steps in lambda order (1.000 → 0.000)
for inp_file in $(ls fep_*.inp | sort -V); do
    echo "Running FEP $inp_file..."
    mpirun -hostfile ${PBS_NODEFILE} Qdyn6p "$inp_file" > "${inp_file%.inp}.log"
done


