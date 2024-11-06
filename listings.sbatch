#!/bin/bash
#SBATCH --account=p31769 ## Required: your allocation/account name, i.e. eXXXX, pXXXX or bXXXX
#SBATCH --partition=normal ## Required: (buyin, short, normal, long, gengpu, genhimem, etc)
#SBATCH --nodes=1 ## how many computers/nodes do you need (no default)
#SBATCH --ntasks-per-node=1 ## how many cpus or processors do you need on per computer/node (default value 1)
#SBATCH --time=12:00:00 ## Required: How long will the job need to run (remember different partitions have restrictions on this parameter)
#SBATCH --mem=4G ## how much RAM do you need per computer/node (this affects your FairShare score so be careful to not ask for more than you need))
#SBATCH --job-name=bl_listings ## When you run squeue -u  this is how you can identify the job
#SBATCH --output=bl_listings.log ## standard out goes to this file
#SBATCH --output=bl_listings.log ## standard error goes to this file