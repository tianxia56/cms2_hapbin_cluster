#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4000

rm sel/*
rm neut/*
rm one_pop_stats/*
rm two_pop_stats/*
rm norm/*
rm hapbin/*
rm slurm-*
rm runtime/*
rm bin/*
rm output/*all*

#for id in {46295909..46295915}; do scancel $id; done
