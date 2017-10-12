#!/bin/bash

#########################################
#### XPROF - Automatic Profiling Tool####
##### Final Built, v0.1 - 12/10/2017 ####
########## Authors/Developer: ###########
### Marco Chiarelli    @ UNISALENTO&CMCC#
### Paolo Panarese     @ UNISALENTO&CMCC#
### Emanuele C. Cesari @ UNISALENTO&CMCC#
######  marco_chiarelli@yahoo.it   ######
######  panarese.paolo@gmail.com   ######
######     cce.9123@gmail.com      ######
#########################################
#########################################

#######################################
####### PERFORMANCE GATHERING #########
###### Paolo Panarese @ UNISALENTO#####
## panarese.paolo@gmail.com 23/05/2017#
#######################################
#######################################

function checkStatus {
	if [[ $1 -gt 0 ]]; then
		echo "Error reached, Quit!"
		exit $1
	fi
}

if [[ $# -lt 1 ]]; then
	echo "INSERT SOURCE FILE"
	exit 1
fi

echo
echo
echo "#########################################"
echo "#### XPROF - Automatic Profiling Tool####"
echo "##### Final Built, v0.1 - 12/10/2017 ####"
echo "########## Authors/Developer: ###########"
echo "### Marco Chiarelli    @ UNISALENTO&CMCC#"
echo "### Paolo Panarese     @ UNISALENTO&CMCC#"
echo "### Emanuele C. Cesari @ UNISALENTO&CMCC#"
echo "######  marco_chiarelli@yahoo.it   ######"
echo "######  panarese.paolo@gmail.com   ######"
echo "######     cce.9123@gmail.com      ######"
echo "#########################################"
echo "#########################################"

echo
echo
echo "#######################################"
echo "####### PERFORMANCE GATHERING #########"
echo "###### Paolo Panarese @ UNISALENTO#####"
echo "## panarese.paolo@gmail.com 23/05/2017#"
echo "#######################################"
echo "#######################################"
echo
echo

NAME=$1
FILENAME="$NAME.c"
PAPI_DIR=$(which papi_avail | sed -e 's/\/bin\/papi_avail/\//g')

if [ -f $FILENAME ]; then
   echo "File $FILENAME exists."
else
   echo "File $FILENAME does not exist."
fi
OPT=""
if [[ $# -gt 1 ]]; then
	OPT=${@:2}
fi
echo "$FILENAME $OPT"

ulimit -s unlimited

echo "Compiling with gprof-oprof flags"
### Compile
gcc -pg -g -O0 $FILENAME -lm -o $NAME $OPT
checkStatus $?

# GPROF
## Dependencies:
# apt install graphviz xdot
# pip install graphviz xdot gprof2dot

echo
echo "********* gprof *********"
### Execute compiled file
./$NAME
checkStatus $?

echo "Creating gprof dir"
rm -r -f gprof
mkdir -p gprof
echo "Running gprof"
gprof ./$NAME > gprof/gprof.out
mv gmon.out gprof/gmon.out
rm -f gmon.out

# OPROF

echo
echo "********* oprof *********"
operf ./$NAME
checkStatus $?
opreport
checkStatus $?
opannotate --source --output-dir=output_oprof `./$NAME`
checkStatus $?

echo "Creating oprof dir and correctly placing oprof.out" 
rm -r -f oprof
mkdir -p oprof
cp output_oprof`pwd`/$FILENAME oprof/oprof.out
echo "Removing some useless stuffs."
rm -r oprofile_data
rm -r output_oprof


# PERFCOUNT

echo
echo "********* perfcount *********"
echo "Creating papi dir."
rm -r -f papi
mkdir -p papi

echo "Compiling base kernel with PAPI (advanced) flags"
echo "gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O0 -lm -o $NAME $FILENAME -lpapi -D PERFCOUNT2"
gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O0 -lm -o $NAME $FILENAME -lpapi -D PERFCOUNT2
checkStatus $?

echo "Compiling optimized kernel with PAPI (advanced) flags"
echo "gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O3 -march=native -lm -o "$NAME"_opt $FILENAME -lpapi -D PERFCOUNT2"
gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O3 -march=native -lm -o "$NAME"_opt $FILENAME -lpapi -D PERFCOUNT2
checkStatus $?

echo "Running base kernel with PAPI (advanced) flags."
echo
./$NAME > papi/perf.out
checkStatus $?

echo "Compiling base kernel with PAPI (basic) flags"
echo "gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O0 -lm -o $NAME $FILENAME -lpapi -D PERFCOUNT"
gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O0 -lm -o $NAME $FILENAME -lpapi -D PERFCOUNT
checkStatus $?

./$NAME >> papi/perf.out
checkStatus $?

echo "Running optimized kernel with PAPI (advanced) flags."
echo

./"$NAME"_opt > papi/perf_opt.out
checkStatus $?

echo "Compiling optimized kernel with PAPI (basic) flags"
echo "gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O3 -march=native -lm -o "$NAME"_opt $FILENAME -lpapi -D PERFCOUNT"
gcc -I$PAPI_DIR""include -L$PAPI_DIR""lib -O3 -march=native -lm -o "$NAME"_opt $FILENAME -lpapi -D PERFCOUNT
checkStatus $?

./"$NAME"_opt >> papi/perf_opt.out
checkStatus $?

HOSTNAME=`hostname`
CACHE_LINE=`cat /proc/cpuinfo | grep cache_alignment | sed 's/^.*:\ //' | sort -u`
B_MAX=3.82828
PEAK_FP=20.8

cd papi

echo "hostname: "$HOSTNAME > machine.out
echo "kernel_name: "$NAME >> machine.out
echo "cache_line: "$CACHE_LINE >> machine.out
echo "b_max: "$B_MAX >> machine.out
echo "peak_fp: "$PEAK_FP >> machine.out

cd ..

echo "Successfully Ended."

