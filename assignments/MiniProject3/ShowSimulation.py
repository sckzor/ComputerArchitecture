import matplotlib.pyplot as plt
import numpy as np

fig, axs = plt.subplots(ncols=4, nrows=2, layout="constrained")

np.random.seed(19680801)  # Fixing random state for reproducibility
file = open("memory_pattern.txt", "r")
text = file.read()

lines = text.split('\n')

data = []

for line in lines:
    if len(line) > 0 and (line[0] == '1' or line[0] == '0'):
        raw_rows = list(map(''.join, zip(*[iter(line)]*8)))
        rows = []
        for row in raw_rows:
            raw_members = list(row)
            members = []
            for member in raw_members:
                members.append(int(member))
            rows.append(members)
        data.append(rows)

im = [[0, 0 , 0], [1, 0, 1], [0, 1, 0]]

for i in range(0, 2):
    for j in range (0, 4):
        axs[i][j].imshow(data[(i * 4) + j])
        axs[i][j].set_title("Generation " + str((i * 4) + j))



plt.show()
