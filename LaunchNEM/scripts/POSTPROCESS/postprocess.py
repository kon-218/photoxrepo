import matplotlib.pyplot as plt
import numpy as np
import sys

# Get the output directory from the command line arguments
workdir= sys.argv[1]
data = sys.argv[2]

# Construct the full path to the data file
data_file = workdir+data  # replace 'data.txt' with your actual data file name
print(data_file)

# Load the data
data = np.loadtxt(data_file)

# Plot the data
plt.plot(data[:, 0], data[:, 1])
plt.show()