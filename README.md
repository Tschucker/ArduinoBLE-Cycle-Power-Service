# ArduinoBLE-Cycle-Power-Service
Implements the BLE Cycle Power Service on Arduino Nano 33 BLE Sense using Magnetometer Sensor

# Required Libraries
* Support for the Arduino Nano 33 BLE Sense Board
* ArduinoBLE
* Nano33BLESensor

# Repo Navigation
alg\_design contains the Matlab algorithm design code along with a python script to collect magnetometer
data from the board once the Nano33BLESensor magnetometer example is loaded. There is also a set of test
data samples in the test\_data folder.

blecyclepower contains the arduino .ino file.

# Usage
This code can be used to implement a simple cycle power and cadence meter when paird with a indoor bicycle
that uses magnetic resistance and simple magnetometer switch to detect cadence. You can then pair the
device to an app such as zwift or RGT to enable virtual rides.

# Blog Post Details
[Arduino BLE Cycling Power Service Blog Post](https://teaandtechtime.com/arduino-ble-cycling-power-service)
