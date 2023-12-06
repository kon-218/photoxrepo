#!/bin/bash

# Script for running full NEM workflow
# Structure of the workflow:
# 1) Pick geometries from the movie.xyz
# 2) Setup ORCA inputs
# 3) Run ORCA calculations
# 4) Parse ORCA outputs
# 5) Calculate spectra and Simulated Annealing

# Pick Geometries from movie.xyz file
../LAUNCH/PickGeoms.sh ../../mol/movie.xyz ../../mol/geoms.xyz 0 0 1 980160
echo "Geometries successfully picked."
echo -e "\n"

# Setup ORCA inputs
../LAUNCH/RecalcGeometries.sh CO ../../mol/ORCA_in 1 0 ../../mol/geoms.xyz ORCA 1 1 ../LAUNCH
echo -e "\n"

# Run ORCA caluculations
# Creates name.output.logs in ORCA_out directory 
../LAUNCH/slurm_run.sh /home/user/orca/orca ../../mol/ORCA_in/ ../../mol/ORCA_out/ ORCA
echo -e "\n"

# Extract ORCA outputs
../PROCESS/ExtractStates.sh CO 5 1 6 "grep_ORCAUV" "_output.log"
echo -e "\n"

#filename=../../mol/Spectrum_data/CO.1-5.n5.s2.exc.dat
filename=../../mol/Spectrum_data/Spectrum_in/CO.1-5.n5.s2.exc.txt
outdir=../../mol/Spectrum_data/Spectrum_out/
workdir=../PROCESS
# Setup Spectra modelling 
../PROCESS/CalcSpectrum.sh CO $filename 5 5 0.1 0.01 false 0 500 1 1 $workdir $outdir 

python3 ../POSTPROCESS/postprocess.py ../../mol/Spectrum_data/Spectrum_out/ absspec..n5.956174.ev.cross.dat