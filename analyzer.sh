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
####### PERFORMANCEANALYZER ###########
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
echo "####### PERFORMANCEANALYZER ###########"
echo "###### Paolo Panarese @ UNISALENTO#####"
echo "## panarese.paolo@gmail.com 23/05/2017#"
echo "#######################################"
echo "#######################################"
echo
echo

### GPROF
## Dependencies:
# apt install graphviz xdot
# pip install graphviz xdot gprof2dot
echo "Generating call graph through gprof2dot and xdot."
cd gprof
### Export to dot file
gprof2dot gprof.out > call_graph.dot
### Convert to png image
dot -Tpng call_graph.dot -o call_graph.png
cd ..

### OPROF
## Dependencies:
# pip install matplotlib
# apt-get install sed
echo "Generating oprof (cumulative) histogram through oprof_graph.py"
cd oprof
cat --number oprof.out | sed 's/\t/\ \ \ \ /' | sed 's/^\ *\([0-9]*\)\ *\([0-9]*\)\ *\([0-9]*\)\ */\1 \2 \3/' | grep ^[0-9]*\ [0-9]*\ [0-9.]*\ *: | sed 's/:.*//' > oprof_data

### print graph with python
python ../oprof_graph.py
checkStatus $?
cd ..


### PERF_RLM
## Dependencies:
# apt install python3-tk
echo "Preparing and exporting vars for TeX Injekt."
cd papi
export GET_DEVELOPER1="Dott. Marco Chiarelli"
export GET_DEVELOPER2="Dott. Paolo Panarese"
export GET_DEVELOPER3="Dott. Emanuele Costa Cesari"
export HOSTNAME=`cat machine.out | grep "hostname" | sed 's/^.*:\ //'`
export KERNEL_NAME=`cat machine.out | grep "kernel_name" | sed 's/^.*:\ //'`

export FP_OPS=`cat perf.out | grep FP_OPS | sed 's/^.*:\ //'`
export L3_TCM=`cat perf.out | grep PAPI_L3_TCM | sed 's/^.*:\ //'`
export L2_TCM=`cat perf.out | grep PAPI_L2_TCM | sed 's/^.*:\ //'`
export TOT_CYC=`cat perf.out | grep PAPI_TOT_CYC | sed 's/^.*:\ //'`
export TOT_INS=`cat perf.out | grep PAPI_TOT_INS | sed 's/^.*:\ //'`
export LLC_PM=`cat perf.out | grep LLC-PREFETCH-MISSES | sed 's/^.*:\ //'`
export LD_INS=`cat perf.out | grep PAPI_LD_INS | sed 's/^.*:\ //'`
export SR_INS=`cat perf.out | grep PAPI_SR_INS | sed 's/^.*:\ //'`
export SC=`cat perf.out | grep UOPS_EXECUTED | sed 's/^.*:\ //'`
export EXEC_TIME=`cat perf.out | grep Execution\ time | sed 's/^.*:\ //' | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }'`

export FP_OPS_OPT=`cat perf_opt.out | grep FP_OPS | sed 's/^.*:\ //'`
if [[ $FP_OPS_OPT -le $FP_OPS ]]; then	
	FP_OPS_OPT=$FP_OPS
fi
export L3_TCM_OPT=`cat perf_opt.out | grep PAPI_L3_TCM | sed 's/^.*:\ //'`
export L2_TCM_OPT=`cat perf_opt.out | grep PAPI_L2_TCM | sed 's/^.*:\ //'`
export TOT_CYC_OPT=`cat perf_opt.out | grep PAPI_TOT_CYC | sed 's/^.*:\ //'`
export TOT_INS_OPT=`cat perf_opt.out | grep PAPI_TOT_INS | sed 's/^.*:\ //'`
export LLC_PM_OPT=`cat perf_opt.out | grep LLC-PREFETCH-MISSES | sed 's/^.*:\ //'`
export LD_INS_OPT=`cat perf_opt.out | grep PAPI_LD_INS | sed 's/^.*:\ //'`
export SR_INS_OPT=`cat perf_opt.out | grep PAPI_SR_INS | sed 's/^.*:\ //'`
export SC_OPT=`cat perf_opt.out | grep UOPS_EXECUTED | sed 's/^.*:\ //'`
export EXEC_TIME_OPT=`cat perf_opt.out | grep Execution\ time | sed 's/^.*:\ //' | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }'`

export CACHE_LINE=`cat machine.out | grep cache_line | sed 's/^.*:\ //'`
export B_MAX=`cat machine.out | grep b_max | sed 's/^.*:\ //'`
export PEAK_FP=`cat machine.out | grep peak_fp | sed 's/^.*:\ //'`

echo "Generating Roofline Model Plot through Python RLMP".
python3 ../rlmp.py $KERNEL_NAME $FP_OPS $L3_TCM $EXEC_TIME $HOSTNAME $CACHE_LINE $B_MAX $PEAK_FP $FP_OPS_OPT $L3_TCM_OPT $EXEC_TIME_OPT > rlm.out

checkStatus $?

cd ../tex_injekt

echo "Running TeX Injekt."
./tex_injekt.sh

cd ..

echo "Successfully ended."
echo
echo "Thanks you for using this program."
echo
echo
