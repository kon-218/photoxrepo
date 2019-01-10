#!/bin/bash

# A simple script that sets the environment for a specific program.
# It should point to the newest version that is available on our clusters.
# This script should work for all PHOTOX clusters.

# TODO: move dftb, g09,cp2k and other to custom_dir
export PHOTOX=/usr/local/programs/custom/PHOTOX

program=$1
# Optional second parameter
if [[ -z $2 ]];then
   version=default
else
   version=$2
fi 

node=$(uname -a | awk '{print $2}' )

function print_help {
   echo "USAGE: source SetEnvironment.sh PROGRAM [VERSION]"
   echo ""
   echo "Available programs are:"
   echo " " 
   echo "${PROGRAMS[@]}" 
   echo " " 
   echo "To find out all available versions of a given PROGRAM, type:"
   echo "SetEnvironment.sh PROGRAM -ver"
   echo "Exiting..."
   return 0
}

function set_version {
   # Check whether given version is available
   for vers in ${VERSIONS[@]};do
      if [[ $version = $vers ]];then
         return 0
      fi
   done

   # Set the default version (first in array VERSIONS)
   if [[ $version = "default" ]];then
      version=${VERSIONS[0]}
      return 0
   fi

   # print available versions if user requests illegal version
   if [[ "$version" != "-ver" ]];then
      echo 1>&2 "Version $version is not available!" 
   fi

   echo 1>&2 "Available versions are:"
   for vers in ${VERSIONS[@]};do
      echo 1>&2  $vers
   done
#   echo ""
   return 1
}

# First, determine where we are. 
if [[ "$node" =~ ^s[0-9]+$|as67-1 ]];then
   cluster=as67
elif [[ "$node" =~ ^a[0-9]+$|403-a324-01 ]];then
   cluster=a324
elif [[ "$node" =~ ^n[0-9]+$|403-as67-01 ]];then
   cluster=as67gpu
elif [[ "$node" =~ ^cn[0-9]+$|^login[0-9] ]];then
   cluster=anselm
else
   echo "I did not recognize any of the PHOTOX clusters. Please check the script SetEnvironment.sh"
   echo "node=$node"
   return 1
fi

if [[ $cluster = "anselm" || $cluster = "salomon" ]];then
   SCRDIR_BASE="/lscratch/$PBS_JOBID/"
   JOB_ID=$PBS_JOBID
else
   SCRDIR_BASE="/scratch/$USER/"
fi

if [[ $cluster = "as67" ]];then
   PROGRAMS=(ABIN GAUSSIAN QCHEM MOLPRO CP2K DFTB ORCA MOPAC GROMACS AMBER OCTOPUS)
elif [[ $cluster = "a324" ]];then
   PROGRAMS=(ABIN GAUSSIAN QCHEM MOLPRO CP2K DFTB ORCA NWCHEM TERACHEM SHARC MOPAC GROMACS AMBER OCTOPUS )
elif [[ $cluster = "as67gpu" ]];then
   PROGRAMS=(ABIN GAUSSIAN QCHEM MOLPRO CP2K DFTB ORCA NWCHEM TERACHEM MOPAC GROMACS AMBER OCTOPUS )
elif [[ $cluster = "anselm" ]];then
   PROGRAMS=(TERACHEM ABIN)
fi

basedir=/usr/local/programs
if [[ $cluster != "as67" ]];then
   basedir=$basedir/common
fi
basedir_custom=/usr/local/programs/custom

if [[ -z $1 ]];then
   echo "SetEnvironment.sh: You did not provide any parameter. Which program do you want to use?"
   print_help 
   return 1
fi

# Check whether $program is available 
available=False
for k in ${!PROGRAMS[@]};do
    if [[ "$program" = ${PROGRAMS[$k]} ]];then
       available=True
       break
    fi
done

if [[ $available = "False" ]];then
   echo "ERROR: Program $program is not available on this cluster."
   print_help 
fi

# declaration of associative BASH arrays
declare -A ABIN NWCHEM OCTOPUS GROMACS ORCA CP2K MOLPRO MOLPRO_MPI GAUSS DFTB TERA MOPAC SHARCH QCHEM QCHEM_MPI


case "$program" in
   "ABIN" )
      if [[ $cluster = "anselm" ]];then
         VERSIONS=(dev-mpi mpi)
         module load  MPICH/3.2-GCC-4.9.3-2.25
      else
         VERSIONS=(1.0 1.0-mpi 1.0-cp2k mpi cp2k)
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      if [[ $version = mpi ]];then
	 if [[ $cluster = anselm ]];then
	    version=dev-mpi
	 else
            version=1.0-mpi
	 fi
      elif [[ $version = cp2k ]];then
         version=1.0-cp2k
      fi
      abinroot=$PHOTOX/bin
      ABIN[1.0]=$abinroot/abin.v1.0
      ABIN[1.0-mpi]=$abinroot/abin.v1.0-mpi
      ABIN[1.0-cp2k]=$abinroot/abin.v1.0-cp2k
      ABIN[cp2k]=$abinroot/abin.cp2k
      ABIN[dev-mpi]=$abinroot/abin.dev.mpi

      export ABINEXE=${ABIN[$version]}
      if [[ "$version" = "1.0-mpi" || "$version" = "1.0-cp2k" ]];then
         export MPIRUN=$basedir_custom/mpich/mpich-3.1.3/arch/x86_64-gcc/bin/mpirun
      elif [[ "$version" = "1.1-cp2k" ]];then
         # TODO: this will be different for ARGON
         source /usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.7.2-settings.sh
         export MPIRUN=/usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.7.2/bin/mpirun
      fi
      ;;
   "MOLPRO" )
      if [[ $cluster = "as67gpu" ]] || [[ $cluster = "a324" ]] ;then
         VERSIONS=( 2012 2015 )
      else
         VERSIONS=( 2012 )
      fi

      MOLPRO[2015]=$basedir_custom/molpro/molpro2015/arch/x86_64_i8
      MOLPRO_MPI[2015]=${MOLPRO[2015]}

      if [[ $cluster = "as67" ]];then
         MOLPRO[2012]=$(readlink -f ${basedir}/molpro/molpro2012.1/arch/amd64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
         MOLPRO_MPI[2012]=$(readlink -f ${basedir}/molpro/molpro2012.1/arch/amd64-intel_12.0.5.220-openmpi_1.6.2/molprop_2012_1_Linux_x86_64_i8)
         export MPIDIR=${basedir}/common/openmpi/openmpi-1.6.5/arch/amd64-intel_12.0.5.220
      else
         MOLPRO[2012]=$(readlink -f ${basedir}/molpro/molpro2012.1/arch/x86_64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
         MOLPRO_MPI[2012]=$(readlink -f ${basedir}/molpro/molpro2012.1/arch/x86_64-intel_12.0.5.220-openmpi_1.6.2/molprop_2012_1_Linux_x86_64_i8)
         export MPIDIR=${basedir}/openmpi/openmpi-1.6.2/arch/x86_64-intel_12.0.5.220
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export molproroot=${MOLPRO[$version]}
      export molpro_mpiroot=${MOLPRO_MPI[$version]}
      export MOLPROEXE=$molproroot/bin/molpro
      export MOLPROEXE_MPI=$molpro_mpiroot/bin/molpro
      if [[ $version = 2015 ]];then
         export MPIDIR=$molproroot
      fi
      export MPIRUN=$MPIDIR/bin/mpirun
      ;;

   "GAUSSIAN" )
      if [[ $cluster = "as67" ]];then
         VERSIONS=( G09.A02 )
      else
         VERSIONS=( G09.D01 G09.A02 )
      fi
      GAUSS[G09.A02]="/home/slavicek/G03/gaussian09/a02/g09"
      if [[ $cluster = "as67gpu" ]];then
         GAUSS[G09.D01]="/home/slavicek/G03/g09-altix/g09/"
      else
         GAUSS[G09.D01]="/home/slavicek/G03/gaussian09/d01/arch/x86_64_sse4.2/g09"
      fi

      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export gaussroot=${GAUSS[$version]}
      GAUSSEXE=$gaussroot/g09
      ;;

   "DFTB" )
      VERSIONS=( 1.2 18.2 )
      DFTB[1.2]=/home/hollas/bin/dftb+
      DFTB[18.2]="$basedir_custom/dftb/dftbplus-18.2.x86_64-linux/bin/dftb+"
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export DFTBEXE=${DFTB[$version]}
      ;;

   "OCTOPUS" )
      VERSIONS=( 6.0 )
      OCTOPUS[6.0]=/home/chalabaj/prog/octopus/Octopus_environment.sh
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      source ${OCTOPUS[$version]}
      ;;

   "AMBER" )
      if [[ $cluster = "as67" ]];then
         VERSIONS=( 11 11-MPI )
      elif [[ $cluster = "a324" ]];then
         VERSIONS=( 12 12-MPI )
      else
         # Version 14 is only AmberTools15 (Containing Sander)
         VERSIONS=( 12 12-MPI 14 14-MPI)
      fi
      AMBER[11]=$basedir/amber/amber11/sub/amber_sp_env.sh
      AMBER[11-MPI]=$basedir/amber/amber11/sub/amber_mp_env.sh
      AMBER[12]=$basedir_custom/amber/amber12/sub/amber_sp_env.sh
      AMBER[12-MPI]=$basedir_custom/amber/amber12/sub/amber_mp_env.sh
      AMBER[14]=$basedir_custom/amber/amber14/arch/intel2015-mpich3.1.3/amber14/amber.sh
      AMBER[14-MPI]=${AMBER[14]}
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      source ${AMBER[$version]}
      ;;

   "TERACHEM" )
      if [[ $cluster = "as67gpu" ]];then
         VERSIONS=( 1.9-dev 1.9 dev trunk azurin )
      elif [[ $node = "a32" || $node = "a33" ]];then
         VERSIONS=( 1.9-dev 1.9 dev trunk )
      elif [[ $cluster = "a324" ]];then
         VERSIONS=( 1.9-dev 1.9 1.5K dev trunk )
      elif [[ $cluster = "anselm" ]];then
         VERSIONS=( trunk )
      fi
      if [[ $cluster = "a324" ]];then
         export LD_LIBRARY_PATH=/usr/local/programs/cuda/driver/usr/lib/:$LD_LIBRARY_PATH
         OPENMMLIB=/usr/local/programs/custom/anaconda/anaconda-4.3.0/arch/x86_64/anaconda3/pkgs/openmm-7.1.1-py36_0/lib/
      elif [[ $cluster = "as67gpu" ]];then
         export LD_LIBRARY_PATH=/usr/local/programs/cuda/driver/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
         OPENMMLIB=/usr/local/programs/custom/anaconda/anaconda-4.1.1/arch/x86_64/pkgs/openmm-7.0.1-py35_0/lib/
      elif [[ $cluster = "anselm" ]];then
         module load  intel/2016a
         module load  CUDA/8.0.44
         module load  MPICH/3.2-GCC-4.9.3-2.25
         source /home/danekhollas/programs/TeraChem-dev/production/setenv
         export LD_LIBRARY_PATH=$CUDA_PATH/lib64/:$LD_LIBRARY_PATH
         export TERAEXE=terachem
         return 0
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi

      # OpenMM library for QM/MM in development version of TC
      export LD_LIBRARY_PATH=$OPENMMLIB:$OPENMMLIB/plugins:$LD_LIBRARY_PATH
      export OPENMM_PLUGIN_DIR=$OPENMMLIB/plugins

      TERA[dev]=$basedir_custom/terachem/terachem-dev/build_mpich
      #DH temporary hack
      TERA[dev]=$basedir_custom/terachem/terachem-1.9dev/build_06092016_7d58b0c7f8b2
      TERA[azurin]=$basedir_custom/terachem/terachem-dev/build_azurin
      TERA[1.5]=$basedir_custom/terachem/terachem-1.5
      TERA[1.5K]=$basedir_custom/terachem/terachem-1.5K
      TERA[1.9-dev]=$basedir_custom/terachem/terachem-1.9dev/build
      TERA[1.9]=$basedir_custom/terachem/terachem-1.9/arch/TeraChem
      TERA[trunk]=/home/hollas/programes/TeraChem-dev/production/build
      if [[ $version != "1.5K" && $version != "1.5" && $version != "1.9" ]];then
         source  /home/hollas/programes/intel/parallel_studio_2015_update5/composerxe/bin/compilervars.sh intel64
      fi
      # TODO: Make SetTCVars.sh for each version and do not export things here...
      export TeraChem=${TERA[$version]}
      export TERAEXE=$TeraChem/terachem
      export PATH=$TeraChem/bin:$PATH
      export NBOEXE=$TeraChem/nbo6.exe
      if [[ $version = "1.9" ]];then
         . $TeraChem/SetTCVars.sh
      elif [[ $version != "1.5" && $version != "1.5K" ]];then
         export LD_LIBRARY_PATH=/home/hollas/programes/intel/parallel_studio_2015_update5/composer_xe_2015.5.223/compiler/lib/intel64/:$LD_LIBRARY_PATH
         export PATH=$basedir_custom/mpich/mpich-3.1.3/arch/x86_64-intel-2015-update5/bin/:$PATH
         export LD_LIBRARY_PATH=$TeraChem/lib:$LD_LIBRARY_PATH
         export LD_LIBRARY_PATH=$basedir_custom/mpich/mpich-3.1.3/arch/x86_64-intel-2015-update5/lib/:$LD_LIBRARY_PATH
         export MPIRUN=$basedir_custom/mpich/mpich-3.1.3/arch/x86_64-intel-2015-update5/bin/mpirun
      elif [[ $version = "1.5K" ]];then
         export LD_LIBRARY_PATH=/usr/local/programs/cuda/cuda-5.0/cuda/lib64/:$LD_LIBRARY_PATH
      elif [[ $version = "1.5" ]];then
         export LD_LIBRARY_PATH=$TeraChem/cudav4.0/cuda/lib64:$LD_LIBRARY_PATH
      fi
      licencepath="/usr/local/programs/custom/PHOTOX/bin/teralicence"
      if [ -x $licencepath ]; then
         $licencepath
      fi
      ;;

   "CP2K" )
      if [[ $cluster = "as67gpu" ]];then
         VERSIONS=(4.1 2.7-trunk 3.0-trunk 2.6.2 2.5 )
         base=/home/hollas/build-fromfrank/
         CP2K[2.5]=$base/cp2k/2_5_12172014/
      elif [[ $cluster = "a324" ]];then
         base=/home/uhlig/build/
         VERSIONS=( 2.5 )
         CP2K[2.5]=$base/cp2k/2.5_11122014/
      elif [[ $cluster = "as67" ]];then
         VERSIONS=( 2.5 )
         base=/home/uhlig/build/
         CP2K[2.5]=$base/cp2k/2_5_12172014/
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi

      if [[ $version = "2.5" ]];then
         . $base/../intel/composer_xe_2013_sp1.4.211/bin/compilervars.sh intel64
         . $base/../intel/composer_xe_2013_sp1.4.211/mkl/bin/mklvars.sh intel64
         . $base/libint/1.1.4-icc/env.sh
         . $base/libxc/2.1.2-icc/env.sh
         . $base/openmpi/1.6.5-icc/env.sh
         . $base/fftw/3.3.4-icc/env.sh
         export MPIRUN=mpirun
      elif [[ $version = "4.1" ]];then
         source /usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.7.2-settings.sh
         CP2K[4.1]=$basedir_custom/cp2k/cp2k-4.1/cp2k-4.1/exe/Linux-x86-64-gfortran_openmpi_mkl/
         export MPIRUN=/usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.7.2/bin/mpirun
      else
         export MPIRUN=/home/hollas/programes/mpich-3.1.3/arch/x86_64-gcc/bin/mpirun
         CP2K[2.6.2]=/home/hollas/programes/src/cp2k-2.6.2/exe/Linux-x86-64-gfortran-mkl/
         CP2K[2.7-trunk]=/home/hollas/programes/src/cp2k-trunk/cp2k/exe/Linux-x86-64-gfortran-mkl-noplumed/
         CP2K[3.0-trunk]=$basedir_custom/cp2k/cp2k-3.0-trunk/src/cp2k/exe/Linux-x86-64-intel-mkl-noplumed/
      fi

      export cp2kroot=${CP2K[$version]}
      export cp2k_mpiroot=${CP2K[$version]}
      export CP2KEXE_MPI=$cp2k_mpiroot/cp2k.popt
      if [[ $cluster = "as67gpu" && $version != "4.1" ]];then 
         export CP2KEXE=$cp2kroot/cp2k.sopt
      else
         export CP2KEXE=$cp2k_mpiroot/cp2k.popt # Frank does not have an sopt version
      fi
      ;;

   "ORCA" )
      VERSIONS=(4.0.0 3.0.3 3.0.2 3.0.0 )
      ORCA[4.0.0]=$basedir_custom/orca/orca_4_0_0_linux_x86-64_openmpi_202/
      ORCA[3.0.0]=$basedir_custom/orca/orca_3_0_0_linux_x86-64_openmpi_165/
      ORCA[3.0.2]=$basedir_custom/orca/orca_3_0_2_linux_x86-64_openmpi_165/
      ORCA[3.0.3]=$basedir_custom/orca/orca_3_0_3_linux_x86-64_openmpi_165/
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      orcaroot=${ORCA[$version]}
      export PATH=$orcaroot/:$PATH
      export ORCAEXE=$orcaroot/orca
      if [[ $cluster = "as67" ]];then
         export OPENMPI=/usr/local/programs/common/openmpi/openmpi-1.6.5/arch/amd64-gcc_4.3.2
      else
         if [[ $version = "4.0.0" ]];then
            if [[ $cluster = "a324" ]];then
               export OPENMPI=$basedir/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.4.5
            else
               export OPENMPI=$basedir/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.7.2
            fi
         else
            export OPENMPI=$basedir/openmpi/openmpi-1.6.5/arch/x86_64-gcc_4.4.5
         fi
      fi
      export PATH=${OPENMPI}/bin:${PATH}
      export LD_LIBRARY_PATH=${OPENMPI}/lib:${LD_LIBRARY_PATH}
      ;;

   "SHARC" )
      VERSIONS=(1.01)
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      if [[ $cluster = "as67" ]];then
         export MOLPRO=$(readlink -f ${basedir}/molpro/molpro2012.1/arch/amd64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
      else
         export MOLPRO=$(readlink -f ${basedir}/molpro/molpro2012.1/arch/x86_64-intel_12.0.5.220/molpros_2012_1_Linux_x86_64_i8)
      fi
      export SHARC=/home/hollas/programes/src/sharc/bin/
      export SCRADIR=/scratch/$USER/scr-sharc-generic_${JOBID}
      echo "Don't forget to set your own unique SCRADIR"
      echo "export SCRADIR=/scratch/$USER/scr-sharc-yourjob/"
      ;;

   "MOPAC" )
      VERSIONS=(2016 2012.15.168 2012.older)
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      MOPAC[2012.15.168]=/usr/local/bin/mopac
      MOPAC[2016]="$basedir_custom/mopac/mopac2016/lib/ld-linux-x86-64.so.2 --library-path $basedir_custom/mopac/mopac2016/lib $basedir_custom/mopac/mopac2016/MOPAC2016.exe"
      if [[ $cluster = "as67" ]];then
         #Somewhat older version, but cannot determine which
         export MOPAC_LICENSE=/home/hollas/programes/MOPAC2012-CENTOS5
         export MOPACEXE=/home/hollas/programes/MOPAC2012-CENTOS5/MOPAC2012.exe
      else
         if [[ $version = "2016" ]];then
	    export MOPAC_LICENSE="$basedir_custom/mopac/mopac2016"
         fi
         export MOPACEXE=${MOPAC[$version]}
      fi
      ;;
   "GROMACS" )
      if [[ $cluster = "as67" ]];then
         VERSIONS=( 4.5.5 )
         GROMACSEXE=mdrun_d
      elif [[ $cluster = "as67gpu" ]];then
         VERSIONS=(5.1  5.1_GPU )
         GROMACSEXE="gmx mdrun"
      else
         VERSIONS=(5.1)
         GROMACSEXE="gmx mdrun"
      fi
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      GROMACS[5.1]=$basedir_custom/gromacs/gromacs-5.1/arch/x86_64-gnu/
      GROMACS[5.1_GPU]=$basedir_custom/gromacs/gromacs-5.1/arch/x86_64-gnu-gpu/
      if [[ $cluster = "as67" ]];then
         source /home/hollas/programes/src/gromacs-4.5.5/scripts/GMXRC.bash
      else
         source ${GROMACS[$version]}/bin/GMXRC.bash
      fi
      ;;

   "QCHEM" )
      VERSIONS=( 4.3 5.0 4.1)
      # TODO version 5.0 MPI only on NEON so far, path in ARGON is different
      if [[ $cluster = "as67" ]];then
         QCHEM[5.0]=$basedir/common/qchem/qchem-5.0/arch/x86_64-multicore
         QCHEM_MPI[5.0]=$basedir/common/qchem/qchem-5.0/arch/x86_64-openmpi
         QCHEM[4.1]=$basedir/common/qchem/qchem-4.1/arch/x86_64
         QCHEM[4.3]=$basedir/common/qchem/qchem-4.3/arch/x86_64
         QCHEM_MPI[4.3]=$basedir/common/qchem/qchem-4.3/arch/x86_64
         QCHEM_MPI[4.1]=$basedir/common/qchem/qchem-4.1/arch/x86_64-openmpi_1.6.5
         #source $basedir/common/openmpi/openmpi-1.6.5/arch/amd64-gcc_4.3.2-settings.sh
      else
         QCHEM[5.0]=$basedir/qchem/qchem-5.0/arch/x86_64-multicore
         QCHEM_MPI[5.0]=$basedir/qchem/qchem-5.0/arch/x86_64-openmpi
         QCHEM[4.1]=$basedir/qchem/qchem-4.1/arch/x86_64
         QCHEM[4.3]=$basedir/qchem/qchem-4.3/arch/x86_64
         QCHEM_MPI[4.3]=$basedir/qchem/qchem-4.3/arch/x86_64
         QCHEM_MPI[4.1]=$basedir/qchem/qchem-4.1/arch/x86_64-openmpi_1.6.5
         #source $basedir/openmpi/openmpi-1.6.5/arch/x86_64-gcc_4.4.5-settings.sh
         #source /usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.4.5-settings.sh     
         #source $basedir/openmpi/openmpi-1.6.5/arch/x86_64-gcc_4.4.5-settings.sh
         #source /usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-gcc_4.4.5-settings.sh     
         #source /usr/local/programs/common/openmpi/openmpi-1.10.7/arch/x86_64-intel_*-settings.sh
      fi
      
      if [[ $cluster = "as67gpu" ]];then
        source /usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-intel_13.1.0.146-settings.sh      
      elif [[ $cluster = "a324" ]] ;then
        source /usr/local/programs/common/openmpi/openmpi-2.0.2/arch/x86_64-intel_12.0.5.220-settings.sh
      fi
      
      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi

      export qcroot=${QCHEM[$version]}
      export qc_mpiroot=${QCHEM_MPI[$version]}
      export QCEXE=$qcroot/bin/qchem
      export QCEXE_MPI=$qc_mpiroot/bin/qchem
      ;;

   "NWCHEM" )
      if [[ $cluster = "as67gpu" ]];then
        VERSIONS=(6.6-beta)
      elif [[ $cluster = "a324" ]];then
        VERSIONS=( 6.6 )
      fi
      NWCHEM[6.6-beta]=$basedir_custom/nwchem/nwchem-6.6beta/src
      NWCHEM[6.6]=$basedir_custom/nwchem/nwchem-6.6/src

      set_version
      if [[ $? -ne 0 ]];then
         return 1
      fi
      export LD_LIBRARY_PATH=$basedir_custom/mpich/mpich-3.1.3/arch/x86_64-gcc/lib/:$LD_LIBRARY_PATH
      export MPIRUN=$basedir_custom/mpich/mpich-3.1.3/arch/x86_64-gcc/bin/mpirun
      export nwchemroot=${NWCHEM[$version]}
      export NWCHEMEXE=$nwchemroot/bin/LINUX64/nwchem
      if [[ ! -d "/scratch/$USER/nwchem_scratch" ]];then
         mkdir /scratch/$USER/nwchem_scratch
      fi

      # Let's recreate this file with each launch
      # which alleviates some problems. Still not great though...
      cat > "/home/$USER/.nwchemrc" << EOF
 nwchem_basis_library $nwchemroot/basis/libraries/
 nwchem_nwpw_library $nwchemroot/nwpw/libraryps/
 ffield amber
 amber_1 $nwchemroot/data/amber_s/
 amber_2 $nwchemroot/data/amber_q/
 amber_3 $nwchemroot/data/amber_x/
 amber_4 $nwchemroot/data/amber_u/
 spce   $nwchemroot/data/solvents/spce.rst
 charmm_s $nwchemroot/data/charmm_s/
 charmm_x $nwchemroot/data/charmm_x/
EOF
      ;;

   * ) 
      echo "$program is not a valid program!"
      print_help
      ;;
esac


