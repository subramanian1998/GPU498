#!/bin/bash
# The interpreter used to execute the script

#“#SBATCH” directives that convey submission options:

#SBATCH --job-name=runmxnet
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=4000m 
#SBATCH --time=01:00
#SBATCH --account=eecs498f20_class
#SBATCH --partition=gpu
#SBATCH --gpus-per-node=1

# The application(s) to execute along with its input arguments and options:

module load gcc/4.8.5
module load openblas/0.3.5
module load cudnn/9.2-v7.6.5
module load cuda/9.2.148

#python submit/submission.py
nvprof python submit/submission.py
