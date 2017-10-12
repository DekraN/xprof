#!/bin/bash 

#######################################
####### TeX Injector for xprof ########
##### Marco Chiarelli @ UNISALENTO#####
## marco_chiarelli@yahoo.it 07/06/2017#
#######################################
#######################################

echo
echo

echo '#######################################'
echo '####### TeX Injector for xprof ########'
echo '##### Marco Chiarelli @ UNISALENTO#####'
echo '## marco_chiarelli@yahoo.it 23/05/2017#'
echo '#######################################'
echo '#######################################'

echo
echo Setting up some variables and subroutines
echo

idx=2
idx2=2
idx3=2

rm -f profiling*
rm -f appendix*
rm -f base*
rm xprof_texbase/*.tex
rm xprof_texbase/*.aux
rm xprof_texbase/*.pdf
rm xprof_texbase/*.log
rm xprof_texbase/chapters/*.tex
rm xprof_texbase/chapters/*.aux

cp tex_base/chapters/profiling.tex profiling$idx.tex
cp tex_base/chapters/appendix.tex appendix$idx2.tex
cp tex_base/base.tex base$idx3.tex

cp ../gprof/call_graph.png xprof_texbase/figures/call_graph.png
cp ../oprof/oprof.png xprof_texbase/figures/oprof.png
cp ../papi/rlm.png xprof_texbase/figures/rlm.png

function process_constant_vars()
{
	local _tex_vars=("${!1}")
	local file="${2}"
	local idx="${3}"

	echo "process_constant_vars(), file: $file"

	for tex_var in "${_tex_vars[@]}"
	do	
		echo "Current variable being processed: $tex_var"
		tmp_name=$(echo $tex_var | sed "s/§//g")
		oldidx=$idx		
		if [ $idx == 2 ]
			then
				idx=3
			else
				idx=2
			fi
			cat $file$oldidx.tex | sed    "s/$tex_var/${!tmp_name}/g" > $file$idx.tex
	done
}

function process_math_vars()
{
	local _tex_vars_math=("${!1}")
	local _tex_vars_math_value=("${!2}")
	local file="${3}"
	local idx="${4}"

	echo "process_math_vars(), file: $file"

	for var_math_idx in $(seq 0 $((${#_tex_vars_math[@]}-1)))
	do		
		var_name=$(echo ${_tex_vars_math[$var_math_idx]} | sed "s/§//g")	
		echo "Current variable being processed: $var_name"	
		echo Related expression is: ${_tex_vars_math_value[$var_math_idx]}	
		export $var_name=$(echo ${_tex_vars_math_value[$var_math_idx]} | bc -l)		
		echo Result is: ${!var_name}
		oldidx=$idx
		if [ $idx == 2 ]
			then
				idx=3
			else
				idx=2
			fi
			cat $file$oldidx.tex | sed    "s/${_tex_vars_math[$var_math_idx]}/${!var_name}/g" > $file$idx.tex
	done
}

function process_derived_math_vars()
{
	local _tex_vars_math_deriv=("${!1}")
	local _tex_vars_math_value_deriv=("${!2}")
	local file="${3}"
	local idx="${4}"

	echo "process_derived_math_vars(), file: $file"
	
	for var_math_idx in $(seq 0 $((${#_tex_vars_math_deriv[@]}-1)))
	do		
		var_name=$(echo ${_tex_vars_math_deriv[$var_math_idx]} | sed "s/§//g")	
		echo "Current variable being processed: $var_name"	
		echo Related expression is: ${_tex_vars_math_value_deriv[$var_math_idx]}	
		declare $var_name=$(echo ${_tex_vars_math_value_deriv[$var_math_idx]} | bc -l)
		echo Result is: ${!var_name}
		oldidx=$idx
		if [ $idx == 2 ]
			then
				idx=3
			else
				idx=2
			fi
			cat $file$oldidx.tex | sed    "s/${_tex_vars_math_deriv[$var_math_idx]}/${!var_name}/g" > $file$idx.tex
	done


}

function process_output_files()
{
	local _tex_output_vars=("${!1}")
	local _tex_output_files=("${!2}")
	local file="${3}"
	local idx="${4}"

	echo "process_output_files(), file: $file"
	
	for var_math_idx in $(seq 0 $((${#tex_output_vars[@]}-1)))
	do	
		echo "Current variable being processed: ${_tex_output_vars[$var_math_idx]}"
		oldidx=$idx
		if [ $idx == 2 ]
			then
				idx=3
			else
				idx=2
			fi
			cat $file$oldidx.tex | sed "s/${_tex_output_vars[$var_math_idx]}/$(sed -e 's/[\&/]/\\&/g' -e 's/$/\\n/' "../${_tex_output_files[$var_math_idx]}" | tr -d '\n')/g" > $file$idx.tex
	done
}

echo
echo Setting up main variables
echo

echo Creating base kernel vars
tex_kernel_vars=(§EXEC_TIME§ §TOT_CYC§ §TOT_INS§ §L2_TCM§ §L3_TCM§ §LLC_PM§ §LD_INS§ §SR_INS§ §FP_OPS§ §SC§)
echo Creating optimized kernel vars
tex_kernel_vars_opt=(§EXEC_TIME_OPT§ §TOT_CYC_OPT§ §TOT_INS_OPT§ §L2_TCM_OPT§ §L3_TCM_OPT§ §LLC_PM_OPT§ §LD_INS_OPT§ §SR_INS_OPT§ §FP_OPS_OPT§ §SC_OPT§ §EXEC_TIME_OPT§)
echo Creating miscellaneous vars
tex_vars=(§KERNEL_NAME§ §GET_DEVELOPER1§ §GET_DEVELOPER2§ §GET_DEVELOPER3§ §CACHE_LINE§ §B_MAX§ §PEAK_FP§)
echo Creating appendix files output vars
tex_output_vars=(§GPROF_OUTPUT§ §OPROF_OUTPUT§ §PAPI_OUTPUT§ §PAPI_OUTPUT_OPT§ §RLM_OUTPUT§ §RLMP_SRC_OUTPUT§ §C_SRC_OUTPUT§ §GATHERING_SRC_OUTPUT§ §ANALYZER_SRC_OUTPUT§ §OPROF_GRAPH_SRC_OUTPUT§)
tex_output_files=("gprof/gprof.out" "oprof/oprof.out" "papi/perf.out" "papi/perf_opt.out" "papi/rlm.out" "rlmp.py" "$KERNEL_NAME.c" "gathering.sh" "analyzer.sh" "oprof_graph.py")
echo Creating math base kernel vars
tex_vars_math=(§GFlops§ §GFLOPS§ §Traffic§ §IPC§ §BMT§ §L2B§ §MFLOPS§ §PSBC§)
echo Creating math optimized kernel vars
tex_vars_math_opt=(§GFlops_OPT§ §GFLOPS_OPT§ §Traffic_OPT§ §IPC_OPT§ §BMT_OPT§ §L2B_OPT§ §MFLOPS_OPT§ §PSBC_OPT§)
echo Creating expressions base kernel vars
tex_vars_math_value=("$FP_OPS/10^9" "$FP_OPS/($EXEC_TIME*10^9)" "($L3_TCM*$CACHE_LINE)/(1024^3)" "$TOT_INS/$TOT_CYC" "$L3_TCM+$LLC_PM" "$L2_TCM*$CACHE_LINE/($EXEC_TIME*1024^2)" "$FP_OPS/($EXEC_TIME*10^6)" "($SC/$TOT_CYC)*100")
echo Creating expressions optimized kernel vars
tex_vars_math_value_opt=("$FP_OPS_OPT/10^9" "$FP_OPS_OPT/($EXEC_TIME_OPT*10^9)" "($L3_TCM_OPT*$CACHE_LINE)/(1024^3)" "$TOT_INS_OPT/$TOT_CYC_OPT" "$L3_TCM_OPT+$LLC_PM_OPT" "($L2_TCM_OPT*$CACHE_LINE)/($EXEC_TIME_OPT*1024^2)" "$FP_OPS_OPT/($EXEC_TIME_OPT*10^6)" "($SC_OPT/$TOT_CYC_OPT)*100")


echo    
echo Processing miscellaneous constant numerical vars..
echo

process_constant_vars tex_vars[@] profiling $idx
process_constant_vars tex_vars[@] appendix $idx2
process_constant_vars tex_vars[@] base $idx3

echo Done.
echo Processing appendix files output vars
	
process_output_files tex_output_vars[@] tex_output_files[@] profiling $idx
process_output_files tex_output_vars[@] tex_output_files[@] appendix $idx2
process_output_files tex_output_vars[@] tex_output_files[@] base $idx3

echo Done.
echo Processing constant numerical vars of kernel base versions..
echo 
process_constant_vars tex_kernel_vars[@] profiling $idx
# process_constant_vars tex_kernel_vars[@] appendix $idx2
# process_constant_vars tex_kernel_vars[@] base $idx3

echo Done.   
echo Processing math vars of kernel base version...
echo 

process_math_vars tex_vars_math[@] tex_vars_math_value[@] profiling $idx
# process_math_vars tex_vars_math[@] tex_vars_math_value[@] appendix $idx2
# process_math_vars tex_vars_math[@] tex_vars_math_value[@] base $idx3

echo Done.    
echo Processing derived math vars of kernel base version...
echo 

tex_vars_math_deriv=(§AI§ §BB§)
tex_vars_math_value_deriv=("$GFlops/$Traffic" "($BMT*$CACHE_LINE)/($EXEC_TIME*1024^2)")

process_derived_math_vars tex_vars_math_deriv[@] tex_vars_math_value_deriv[@] profiling $idx
# process_derived_math_vars tex_vars_math_deriv[@] tex_vars_math_value_deriv[@] appendix $idx2
# process_derived_math_vars tex_vars_math_deriv[@] tex_vars_math_value_deriv[@] base $idx3

echo Done.
echo
echo Processing constant numerical vars of kernel optimized versions..

process_constant_vars tex_kernel_vars_opt[@] profiling $idx
# process_constant_vars tex_kernel_vars_opt[@] appendix $idx2
# process_constant_vars tex_kernel_vars_opt[@] base $idx3

echo Done. 
echo
echo Processing math vars of kernel optimized version...

process_math_vars tex_vars_math_opt[@] tex_vars_math_value_opt[@] profiling $idx
# process_math_vars tex_vars_math_opt[@] tex_vars_math_value_opt[@] appendix $idx2
# process_math_vars tex_vars_math_opt[@] tex_vars_math_value_opt[@] base $idx3

echo Done. 
echo
echo Processing derived math vars of kernel optimized version...

tex_vars_math_deriv_opt=(§AI_OPT§ §BB_OPT§)
tex_vars_math_value_deriv_opt=("$GFlops_OPT/$Traffic_OPT" "($BMT_OPT*$CACHE_LINE)/($EXEC_TIME_OPT*1024^2)")

process_derived_math_vars tex_vars_math_deriv_opt[@] tex_vars_math_value_deriv_opt[@] profiling $idx
# process_derived_math_vars tex_vars_math_deriv_opt[@] tex_vars_math_value_deriv_opt[@] appendix $idx2
# process_derived_math_vars tex_vars_math_deriv_opt[@] tex_vars_math_value_deriv_opt[@] base $idx3

echo Done.
echo
echo Removing some unused files

mv profiling$idx.tex xprof_texbase/chapters/profiling.tex
mv appendix$idx2.tex xprof_texbase/chapters/appendix.tex
mv base$idx3.tex "xprof_texbase/$KERNEL_NAME.tex"
rm -f profiling*
rm -f appendix*
rm -f base*
rm -f $KERNEL_NAME*

echo Done.
echo
echo TeX Compiling

cd "xprof_texbase"
pdflatex "$KERNEL_NAME.tex"
pdflatex "$KERNEL_NAME.tex" > /dev/null

cp "$KERNEL_NAME.pdf" ../../"$KERNEL_NAME.pdf"

echo Done.
echo
echo 'Thank you for using this program.'
echo 
echo 

