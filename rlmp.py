#######################################
####### Roofline Model Plotter ########
##### Marco Chiarelli @ UNISALENTO#####
## marco_chiarelli@yahoo.it 23/05/2017#
#######################################
#######################################

import numpy as np

import matplotlib.pyplot as plt
import matplotlib.ticker as mtick

from sys import argv

argc = len(argv)
optimized = argc >= 11

# Verbose Settings
# useful for debugging
verbose_machine = argc > 12 and bool(argv[12]) or True
verbose_kernel = argc > 13 and bool(argv[13]) or True
autosave = argc > 14 and bool(argv[14]) or True

if argc < 9:
    print("Error: Invalid number of arguments.")
    exit(0)
    
# Kernel Info
your_kernel_name = str(argv[1])
your_machine_name = str(argv[5])
Flops = int(argv[2])
Gflops = Flops/(10**9)
L3CM = int(argv[3])
etime = float(argv[4])
GFLOPS = Gflops/etime # y coordinate

global Flops_opt
global Gflops_opt
global L3CM_opt
global etime_opt
global GFLOPS_opt
global traffic_opt
global arithmetic_int_opt

# Machine Info
L3LineSize = int(argv[6]) # LL cache line size
bmax = float(argv[7]) # maximum bandwidth;
peak_fp_performance = float(argv[8]) # GFLOPS/s
ridge_point = peak_fp_performance/bmax
sample_y = round(2*bmax, 2)

if optimized:
    Flops_opt = int(argv[9])
    Gflops_opt = Flops_opt/(10**9)
    L3CM_opt = int(argv[10])
    etime_opt = float(argv[11])
    GFLOPS_opt = Gflops_opt/etime_opt
    traffic_opt = (L3CM_opt*L3LineSize)/(1024**3)
    arithmetic_int_opt = Gflops_opt/traffic_opt # x coordinate

# Some other stuffs
traffic = (L3CM*L3LineSize)/(1024**3)
arithmetic_int = Gflops/traffic

def printline():
    print("--------------------------------------------------")

def printKernel(your_kernel_name, Flops, L3CM, etime, Gflops, GFLOPS, traffic, arithmetic_int):
    printline()
    print(your_kernel_name + " - Roofline Model (RLM)")
    printline()
    print("Floating Point Operations (Flops) = " + str(Flops) + ";")
    print("L3 Cache Misses = " + str(L3CM) + ";")
    print("Execution time = " + str(etime) + ";")
    print("Gflops = " + str(Gflops) + ";")
    print("GFLOPS = " + str(GFLOPS) + ";")
    print("Traffic = " + str(traffic) + " GB;")
    print("Arithmetic Intensity (AI) = " + str(arithmetic_int) + " Gflops/GB.")
    printline()
    print("Your kernel: " + your_kernel_name+";")
    print("is: " + (arithmetic_int > ridge_point and "COMPUTE" or "MEMORY") + " BOUNDED!")
    print("with respect to the machine: ")
    print(your_machine_name+".")
    printline()
    print(" ")
    print(" ")

printline()
print("####### Roofline Model Plotter ########")
print("#######################################")
print("##### Marco Chiarelli @ UNISALENTO#####")
print("## marco_chiarelli@yahoo.it 23/05/2017#")
print("#######################################")
printline()


if verbose_machine == True:
    printline()
    print(your_machine_name)
    print("Listing some machine informations...")
    printline()
    print("L3LineSize = " + str(L3LineSize) + " byte;")
    print("Peak Memory BW = " + str(bmax) + " GB/s;")
    print("Peak FP Performance = " + str(peak_fp_performance) + " Gflops/s;")
    print("Corresponding Ridge point = " + str(ridge_point) + ".")
    printline()
    print(" ")
    print(" ")

if verbose_kernel == True:
    printKernel(your_kernel_name, Flops, L3CM, etime, Gflops, GFLOPS, traffic, arithmetic_int) 

    if optimized == True:
        printKernel("Optimized "+your_kernel_name, Flops_opt, L3CM_opt, etime_opt, Gflops_opt, GFLOPS_opt, traffic_opt, arithmetic_int_opt) 

if optimized == True:
    gain_performance = ((GFLOPS_opt-GFLOPS)/GFLOPS)*100;
    gain_memory = ((arithmetic_int_opt-arithmetic_int)/arithmetic_int)*100;
    print("Percentual Performance Gain: " + str(gain_performance)+ ";")
    print("Percentual Memory Gain: " + str(gain_memory) + ";")
    print("Done a " + (gain_performance > 0 and "good" or "bad") + " job wrt FP performance;")
    print("Done a " + (gain_memory > 0 and "good" or "bad") + " job wrt memory.")
    print(" ")
    print(" ")

# Preparing a straight line fitting
xP = [ridge_point, 2]
yP = [peak_fp_performance, sample_y]

coefficients = np.polyfit(xP, yP, 1)
polynomial = np.poly1d(coefficients)
x_axis = np.linspace(0,20,100)
peak_memory_BW_plt = polynomial(x_axis)
peak_fp_performance_plt = np.ones(len(x_axis))*peak_fp_performance

# PLOT SETTINGS
logbase = 2
fig, ax = plt.subplots()
# Machine RLM plot
ax.loglog(np.where(x_axis >= ridge_point, 0, x_axis),np.where(peak_memory_BW_plt >= peak_fp_performance, 0, peak_memory_BW_plt),'-',basex=logbase,basey=logbase,linewidth=2.5)
ax.loglog(np.where(x_axis >= ridge_point, x_axis, 0),np.where(peak_fp_performance_plt > peak_memory_BW_plt, 0, peak_fp_performance_plt),'-',basex=logbase,basey=logbase,linewidth=2.5)
ax.loglog(ridge_point, peak_fp_performance,'+',basex=logbase,basey=logbase,markeredgewidth=3,markersize=10)
# Kernel(s) plot
ax.loglog(arithmetic_int, GFLOPS,'o',basex=logbase,basey=logbase)
if optimized == True:
    ax.loglog(arithmetic_int_opt, GFLOPS_opt,'o',basex=logbase,basey=logbase)

def ticks(y, pos):
    return r'$2^{:.0f}$'.format(np.log2(y))

#ax.xaxis.set_major_formatter(mtick.FuncFormatter(ticks))
#ax.yaxis.set_major_formatter(mtick.FuncFormatter(ticks))

# PLOT
plt.grid(True, which="both", ls="-")
plt.xlabel("Arithmetic Intensity AI [GFlops/GB]")
plt.ylabel("Attainable Performance [GFLOPS = GFlops/s]")
plt.legend(optimized == True and ["Peak Memory BW", "Peak FP Performance", "Ridge Point", "Your Kernel", "Your Optimized Kernel"] or ["Peak Memory BW", "Peak FP Performance", "Ridge Point", "Your Kernel"], loc='best')
plt.title("Roofline Model (RLM) of: " + your_kernel_name)

if autosave:
    fig.savefig("rlm.png", dpi=96 * 10)
else:
    plt.show()

print("Thank you for using this program.")
print(" ")
print(" ")
