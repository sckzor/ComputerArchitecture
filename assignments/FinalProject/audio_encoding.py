from scipy.io import wavfile
import scipy.signal as sps
sampling_rate, data = wavfile.read("LandLshort.wav")

print(f"The sampling rate is {sampling_rate} Hz")
print(f"There are {len(data)} samples in the file")

with open("landl.txt", "w", encoding="utf-8") as f:
    for point in data:
        f.write(f"{point:x}\n")
