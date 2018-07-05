# ESP32.MQTT.to.UART.Gateway
Implements a basic MQTT to UART gateway using the ESP32 devC board and LuaRTOS.
You will need to have an MQTT broker setup and an ESP32 flashed with the latest LuaRTOS.
I used UART2 for the gateway, GPIO2 for the Wifi active LED, and GPIO0 to indicate gateway activity.
Uart2 is mapped to the default pins, GPIO 16,17.

## Instructions to use
1. Set the macros for Wifi and Mqtt broker to match your requirements
  --your wifi ssid
_yourssid = "yourwifissid"
--your wifipwd
_yourwifipwd = 'wifipassword'

--MQTT vars 
--broker info
_yourMqttBokerUrl = "yourMqttBrokerUrl" --example if you use CloudMqtt "m10.cloudmqtt.com"
_yourMqttClientId = "yourClientId" --example of what I named my client ID on CloudMqtt "/HVAC1"
_yourMqttUid = "yourUid" --
_yourMqttPwd = "yourPwd" --
_yourMqttPort = 18967 --18967

2. Connect a target board of your choosing to interface with the the ESP32 by connecting the returns and the UART TX and RX pins.

3. Setup your topic subscriptions.
   Replace the topic subscriptions with your own 
     -- subscribe to topic
			_mqtt:subscribe('/TOHVAC/SET/TEMP', mqtt.QOS0, function(length, payload)
			
