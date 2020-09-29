#include "Arduino.h"
/* For the bluetooth funcionality */
#include <ArduinoBLE.h>
/* For the use of the IMU sensor */
#include "Nano33BLEMagnetic.h"

/* Device name which can be scene in BLE scanning software. */
#define BLE_DEVICE_NAME               "Arduino Nano 33 BLE Sense"
/* Local name which should pop up when scanning for BLE devices. */
#define BLE_LOCAL_NAME                "Cycle Power BLE"

Nano33BLEMagneticData magneticData;

BLEService CyclePowerService("1818");
BLECharacteristic CyclePowerFeature("2A65", BLERead, 4);
BLECharacteristic CyclePowerMeasurement("2A63", BLERead | BLENotify, 8);
BLECharacteristic CyclePowerSensorLocation("2A5D", BLERead, 1);

unsigned char bleBuffer[8];
unsigned char slBuffer[1];
unsigned char fBuffer[4];

short power;
unsigned short revolutions = 0;
unsigned short timestamp = 0;
unsigned short flags = 0x20;
byte sensorlocation = 0x0D;

float tm2 = 0;
float tm1 = 0;
float tm0 = 0;

float min_m2 = 100;
float max_m2 = 0;
float min_m1 = 100;
float max_m1 = 0;
float curr_min = 100;
float curr_max = 0;
bool is_static = true;

double i_prev = 0;
double i_curr = 0;
double i_diff = 0;
bool point = false;
double counter = 0;

//Configurable values
float mag_power_calib = 100;
double mag_samps_per_sec = 16;
short cap_power = 400;
float decay_factor = 0.5;
float noise_factor = 3;

void setup() 
{
  // put your setup code here, to run once:
  /* BLE Setup. For information, search for the many ArduinoBLE examples.*/
  if (!BLE.begin()) 
  {
    while (1);    
  }
  else
  {
    BLE.setDeviceName(BLE_DEVICE_NAME);
    BLE.setLocalName(BLE_LOCAL_NAME);
    BLE.setAdvertisedService(CyclePowerService);
    CyclePowerService.addCharacteristic(CyclePowerFeature);
    CyclePowerService.addCharacteristic(CyclePowerMeasurement);
    CyclePowerService.addCharacteristic(CyclePowerSensorLocation);

    BLE.addService(CyclePowerService);
    BLE.advertise();

    Magnetic.begin();
   }       
}

void loop() 
{
  // put your main code here, to run repeatedly:
  BLEDevice central = BLE.central();
  if(central)
  {     
    /* 
    If a BLE device is connected, magnetic data will start being read, 
    and the data will be processed
    */
    while(central.connected())
    {            
      if(Magnetic.pop(magneticData))
      {
        /* 
        process magnetic data into power, revolutions, and timestamp
        */
        counter = counter + 1;
        tm0 = magneticData.z;
        
        if(tm2 > curr_max)
        {
           curr_max = tm2;
        }
        else
        {
           curr_max = curr_max - decay_factor;
        }
        
        if(tm2 < curr_min)
        {
           curr_min = tm2;
        }
        else
        {
           curr_min = curr_min + decay_factor;
        }

        if(((tm1-tm2) < 0) && ((tm1-tm0) < 0))
        {
            point = true;
        }
        else
        {
            point = false;
        }

        if((((curr_max+max_m1+max_m2)/3) - ((curr_min+min_m1+min_m2)/3)) < noise_factor)
        {
          is_static = true;
        }
        else
        {
          is_static = false;
        }

        if((tm1 < (curr_max - curr_min)) && point && (~is_static))
        {
          i_curr = counter-1;
          i_diff = i_curr - i_prev;

          power = short(((mag_power_calib - curr_max)*(mag_power_calib - curr_max))*(60/(i_diff*(1024/mag_samps_per_sec))));
          if(power > cap_power)
          {
            power = cap_power;
          }
          revolutions = revolutions + 1;
          timestamp = timestamp + (unsigned short)(i_diff*(1024/mag_samps_per_sec));
          i_prev = i_curr;

          bleBuffer[0] = flags & 0xff;
          bleBuffer[1] = (flags >> 8) & 0xff;
          bleBuffer[2] = power & 0xff;
          bleBuffer[3] = (power >> 8) & 0xff;
          bleBuffer[4] = revolutions & 0xff;
          bleBuffer[5] = (revolutions >> 8) & 0xff;
          bleBuffer[6] = timestamp & 0xff;
          bleBuffer[7] = (timestamp >> 8) & 0xff;

          slBuffer[0] = sensorlocation & 0xff;

          fBuffer[0] = 0x00;
          fBuffer[1] = 0x00;
          fBuffer[2] = 0x00;
          fBuffer[3] = 0x08;
         
          CyclePowerFeature.writeValue(fBuffer, 4);
          CyclePowerMeasurement.writeValue(bleBuffer, 8);
          CyclePowerSensorLocation.writeValue(slBuffer, 1);
        }
        tm2 = tm1;
        tm1 = tm0;
        max_m2 = max_m1;
        max_m1 = curr_max;
        min_m2 = min_m1;
        min_m1 = curr_min;   
      }
    }
  }
}
