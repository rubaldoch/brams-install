#!/bin/bash

#########################################################
#
#   Script to install BRAMS 6 in a HPC cluster using
#   gcc 8.4.0
#
########################################################

## Locate current folder
FOLDER=$(pwd)
BUILD_DIR=$FOLDER/build
INSTALL_DIR=$FOLDER/install
BRAMS_DIR=$FOLDER/brams

## Create folder for reqs
mkdir -p $BUILD_DIR/bin #YOUR_DIR
mkdir -p $BUILD_DIR/lib
mkdir -p $BUILD_DIR/include
mkdir $INSTALL_DIR
mkdir -p $BRAMS_DIR/bin/tables

## Download all prerequisites
cd $INSTALL_DIR
wget http://ftp.cptec.inpe.br/pesquisa/bramsrd/BRAMS/pre-requisites/prerequisites.tar
tar -xvf prerequisites.tar

## Setup paths
export PATH=$BUILD_DIR/bin:$PATH
export LD_LIBRARY_PATH=$BUILD_DIR/lib:$LD_LIBRARY_PATH
ln -s /usr/bin/gfortran $BUILD_DIR/bin/gfortran
ln -s /usr/bin/gcc $BUILD_DIR/bin/gcc

## Check paths and compiler versions
echo $PATH
echo $LD_LIBRARY_PATH
gfortran --version
gcc --version

## Install MPICH 
cd $INSTALL_DIR
tar -xzvf mpich-4.0a2.tar.gz 
cd mpich-4.0a2/
unset F90
unset F90FLAGS
./configure -disable-fast CC=gcc FC=gfortran \
CFLAGS=-O2 FFFLAGS=-O2 CXXFLAGS=-O2 FCFLAGS=-O2 \
--prefix=$BUILD_DIR --with-device=ch3 --with-hwloc=embedded
make && make install

### Check mpich instalation files
ls $BUILD_DIR/bin
### Check mpich version
$BUILD_DIR/bin/mpirun --version

## Install ZLIB 
cd $INSTALL_DIR
tar -xzvf zlib-1.2.8.tar.gz 
cd zlib-1.2.8/
CC=gcc ./configure --prefix=$BUILD_DIR
make && make install

## Install SZIP 
cd $INSTALL_DIR
tar -xzvf szip-2.1.tar.gz 
cd szip-2.1/
CC=gcc ./configure --prefix=$BUILD_DIR
make && make install

## Install CURL 
cd $INSTALL_DIR
tar -xzvf curl-7.26.0.tar.gz 
cd curl-7.26.0/
CC=gcc ./configure --prefix=$BUILD_DIR --without-libssh2  --with-openssl
make && make install

## Install HDF5
cd $INSTALL_DIR
tar -xzvf hdf5-1.12.1.tar.gz 
cd hdf5-1.12.1/
./configure --prefix=$BUILD_DIR CC=$BUILD_DIR/bin/mpicc \
FC=$BUILD_DIR/bin/mpif90 --with-zlib=$BUILD_DIR \
--with-szlib=$BUILD_DIR --enable-parallel --enable-fortran
make && make install

## Install NETCDF-C 
cd $INSTALL_DIR
tar -xzvf netcdf-c-4.8.1.tar.gz 
cd netcdf-c-4.8.1/
CPPFLAGS=-I$BUILD_DIR/include LDFLAGS=-L$BUILD_DIR/lib CFLAGS='-O3' \
CC=$BUILD_DIR/bin/mpicc ./configure --prefix=$BUILD_DIR --enable-netcdf4 \
--enable-shared --enable-dap
make && make install

## Install NETCDF-F 
cd $INSTALL_DIR
tar -xzvf netcdf-fortran-4.5.3.tar.gz
cd netcdf-fortran-4.5.3/
CPPFLAGS=-I$BUILD_DIR/include LDFLAGS=-L$BUILD_DIR/lib \
CFLAGS='-O3' FC=$BUILD_DIR/bin/mpif90  CC=$BUILD_DIR/bin/mpicc \
./configure --prefix=$BUILD_DIR

## Install GRIB2
cd $INSTALL_DIR
wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
tar -zxvf wgrib2.tgz
cd grib2
# Edit grib2/makefile according to https://github.com/luflarois/brams/blob/master/doc/BRAMS_6.0_-_INSTALL_PREREQUISITES.md
rm makefile
wget https://raw.githubusercontent.com/rubaldoch/brams-install/main/wgrib/makefile
make CC=gcc FC=gfortran
make CC=gcc FC=gfortran lib
cp wgrib2/wgrib2 $BUILD_DIR/bin/
cp wgrib2/libwgrib2.a $BUILD_DIR/lib/
cp ./lib/*.a $BUILD_DIR/lib/
cp ./lib/*.mod $BUILD_DIR/include/


## Install BRAMS 6.0
cd $INSTALL_DIR
git clone https://github.com/luflarois/brams.git
cd brams
cp Bin_files/variables.csv .
cd build
./configure --program-prefix=BRAMS_6.0 --prefix=$FOLDER/brams --enable-jules \
--with-chem=RELACS_TUV --with-aer=SIMPLE --with-fpcomp=$BUILD_DIR/bin/mpif90 \
--with-cpcomp=$BUILD_DIR/bin/mpicc --with-fcomp=gfortran --with-ccomp=gcc \
--with-netcdff=$BUILD_DIR --with-netcdfc=$BUILD_DIR --with-wgrib2=$BUILD_DIR
##  compile brams
make
make install
##  compile filter
make filter
make install-filter
##  compile pre-brams
make pre-brams
make install-pre-brams

echo "Installation finished!!!!!"
