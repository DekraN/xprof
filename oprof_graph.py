import numpy as np
import matplotlib.pyplot as plt

graphXDelay = 3

x = []
y = []
xLabel = []

file = open("oprof_data", "r") 
lines = file.readlines()

for line in lines:
	splitted = str(line).split(' ')
	x.append(int(splitted[0]))
	if len(x) % graphXDelay == 0:
		xLabel.append(splitted[0])
	else:
		xLabel.append("")
	if len(splitted) > 3:
		y.append(float(splitted[1]))
	else:
		y.append(0)

ind = np.arange(len(y))

width = 0.35       # the width of the bars

fig, ax = plt.subplots()

rects = ax.bar(ind, y, width, color='b')

lineY = np.cumsum(y)
lineGraph = ax.plot(ind, lineY, 'r')

ax.set_title('oprof')
ax.set_xticks(ind + width / 2)
ax.set_xticklabels(xLabel)

ax.legend((rects[0], lineGraph[0]), ("Samples", "Cumulative Sum"))

#plt.show()
#fig.savefig('oprof.png')
fig.savefig('oprof.png', dpi=96 * 10)



