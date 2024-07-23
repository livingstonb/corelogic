#!/bin/bash
#SBATCH --job-name=clogic-brian
#SBATCH --output=/home/blt2697/charlie-project/corelogic/output/sbatch.out
#SBATCH --error=/home/blt2697/charlie-project/corelogic/output/sbatch.err
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=8000

module load stata/17

stata-mp -b do main.do -memsize 8G