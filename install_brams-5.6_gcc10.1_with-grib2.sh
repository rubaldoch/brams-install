#!/bin/bash


#########################################################
#
#   Script to install BRAMS 5.6 in a HPC cluster using
#   gcc 10.1.0 with wgrib2 support
#
########################################################


## Load Compiler Modules
module load gcc/10.1.0

## Locate current folder
FOLDER=$(pwd)

## Create folder for reqs
mkdir -p requirements/src
mkdir -p requirements/build

## Install MPICH 
cd $FOLDER/requirements/src
wget https://www.mpich.org/static/downloads/4.0.2/mpich-4.0.2.tar.gz
tar -zxvf mpich-4.0.2.tar.gz
cd mpich-4.0.2/
unset F90
unset F90FLAGS

./configure --disable-fast CFLAGS=-O2 FFLAGS=-fallow-argument-mismatch \
CXXFLAGS=-O2 FCFLAGS=-fallow-argument-mismatch --with-ucx=embedded \
--prefix=$FOLDER/requirements/build CC=gcc FC=gfortran F77=gfortran
make && make install

## Install GRIB2
cd $FOLDER/requirements/src
wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
tar -zxvf wgrib2.tgz
cd grib2
# Edit grib2/makefile according to http://ftp.cptec.inpe.br/pesquisa/bramsrd/BRAMS/releases/beta/BRAMS-5.6/BRAMS_INSTALL_COMPLETE_MANUAL.pdf
rm makefile
wget https://raw.githubusercontent.com/rubaldoch/brams-install/main/wgrib/makefile
make CC=gcc FC=gfortran
make CC=gcc FC=gfortran lib
cd $FOLDER/requirements/src
# cp -r grib2/* $FOLDER/requirements/build
cp -r grib2/lib/* $FOLDER/requirements/build/include

## Install Curl
cd $FOLDER/requirements/src
wget --no-check-certificate https://curl.haxx.se/download/curl-7.65.0.tar.gz
tar -xvf curl-7.65.0.tar.gz
cd curl-7.65.0
./configure --without-zlib CC=gcc FC=gfortran --prefix=$FOLDER/requirements/build
make
make install

## Install M4
cd $FOLDER/requirements/src
wget http://ftp.gnu.org/gnu/m4/m4-latest.tar.gz
tar -xvf m4-latest.tar.gz 
cd m4-1.4.19/
./configure --prefix=$FOLDER/requirements/build/ LDFLAGS="-L$FOLDER/requirements/build/lib" \
CPPFLAGS="-I$FOLDER/requirements/build/include"
make
make install

## Install Zlib
cd $FOLDER/requirements/src
wget https://zlib.net/fossils/zlib-1.2.11.tar.gz
tar -xvf zlib-1.2.11.tar.gz 
cd zlib-1.2.11/
./configure --prefix=$FOLDER/requirements/build/ --libdir=$FOLDER/requirements/build/lib/ \
--includedir=$FOLDER/requirements/build/include
make 
make install 

## Install NetCDF C
cd $FOLDER/requirements/src
#wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-c-4.7.0.tar.gz
tar -xvf netcdf-c-4.7.0.tar.gz 
cd netcdf-c-4.7.0/
./configure --prefix=$FOLDER/requirements/build/ LDFLAGS="-L$FOLDER/requirements/build/lib"  \
CPPFLAGS="-I$FOLDER/requirements/build/include" LT_SYS_LIBRARY_PATH=$FOLDER/requirements/build/lib \
--disable-share --disable-netcdf-4 --disable-dap-remote-tests FC=gfortran CC=gcc
make
make check
make install

## Install NetCDF F
cd $FOLDER/requirements/src
#wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.4.5.tar.gz
tar -xvf v4.4.5.tar.gz
cd netcdf-fortran-4.4.5/
export LD_LIBRARY_PATH=$FOLDER/requirements/build/lib:$LD_LIBRARY_PATH
# to fix https://github.com/Unidata/netcdf-fortran/issues/212
export FCFLAGS="-w -fallow-argument-mismatch -O2"
export FFLAGS="-w -fallow-argument-mismatch -O2"
./configure --prefix=$FOLDER/requirements/build/ LDFLAGS="-L$FOLDER/requirements/build/lib" \
CPPFLAGS="-I$FOLDER/requirements/build/include"  LT_SYS_LIBRARY_PATH=$FOLDER/requirements/build/lib \
--disable-shared  FC=gfortran CC=gcc
make
make check 
make install

## Install BRAMS 5.6
cd $FOLDER/requirements/src
wget http://ftp.cptec.inpe.br/pesquisa/bramsrd/BRAMS/releases/stable/brams-5.6.2.tar.xz
tar -xvf brams-5.6.2.tar.xz
cd BRAMS-5.6/build
./configure --program-prefix=BRAMS --prefix=$FOLDER/requirements/build --enable-jules \
--with-chem=RELACS_TUV --with-aer=SIMPLE --with-fpcomp=$FOLDER/requirements/build/bin/mpif90 \
--with-cpcomp=$FOLDER/requirements/build/bin/mpicc --with-fcomp=gfortran \
--with-ccomp=gcc --with-wgrib2=$FOLDER/requirements/build \
LDFLAGS="-L$FOLDER/requirements/build/lib/ -L$FOLDER/requirements/build/" \
CPPFLAGS"-I$FOLDER/requirements/build/include"
make
make install

## Download Table http://ftp.cptec.inpe.br/pesquisa/bramsrd/BRAMS/files/tables_old_versions/bramsTablesRev2000.tgz
## Download Metereo http://ftp.cptec.inpe.br/pesquisa/bramsrd/BRAMS_5.4/BRAMS/data/meteo-only.tgz
## Download Chem http://ftp.cptec.inpe.br/pesquisa/bramsrd/BRAMS_5.4/BRAMS/data/meteo-chem.tgz
