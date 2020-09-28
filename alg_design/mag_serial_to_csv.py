import serial
import time
import csv
import matplotlib
matplotlib.use("tkAgg")
import matplotlib.pyplot as plt
import numpy as np

ser = serial.Serial('/dev/cu.usbmodem14201')
ser.flushInput()

plot_window = 20
y_var = np.array(np.zeros([plot_window]))

plt.ion()
fig, ax = plt.subplots()
line, = ax.plot(y_var)

while True:
    try:
        ser_bytes = ser.readline()
        #print(ser_bytes)
        try:
            decoded_bytes = ser_bytes.decode('ascii')
            print(decoded_bytes)
            split_decoded_bytes = decoded_bytes.split(",")
            magX = float(split_decoded_bytes[0])
            magY = float(split_decoded_bytes[1])
            magZ = float(split_decoded_bytes[2])
        except:
            continue
        
        with open("test_data.csv","a") as f:
            writer = csv.writer(f,delimiter=",")
            writer.writerow([magX,magY,magZ])
        y_var = np.append(y_var,magZ)
        y_var = y_var[1:plot_window+1]
        line.set_ydata(y_var)
        ax.relim()
        ax.autoscale_view()
        fig.canvas.draw()
        fig.canvas.flush_events()
    except:
        print("Keyboard Interrupt")
        break
