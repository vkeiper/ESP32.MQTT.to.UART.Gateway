require("block")
-- Author: Vincent G. Keiper III
-- ESP32 MQTT to UART gateway
-- Written using LuaRTOS 
-- Version 1.0.1
-- Date: 20180705_1650

-- this event is for sync the end of the board start with threads
-- that must wait for this situation
_eventBoardStarted = event.create()

-- this event is for sync the end of the wifi start with threads
-- that must wait for this situation
_eventWifiStarted = event.create()

-- this lock is for protect the mqtt client connection
_mqtt_lock = thread.createmutex()
--your wifi ssid
_yourssid = "yourssid"
--your wifipwd
_yourwifipwd = 'yourpwd'

--MQTT vars 
--broker info
_yourMqttBrokerUrl = "your.cloudmqtt.com" --example if you use CloudMqtt "m10.cloudmqtt.com"
_yourMqttClientId = "/HVAC1" --example of what I named my client ID on CloudMqtt "/HVAC1"
_yourMqttUid = "youruid" --
_yourMqttPwd = "yourpwd" --
_yourMqttPort = 18967 --18967

--MQTT publish topics
_strMQTTPUBwificonn = '/FROMHVAC/SET/WIFI'

--MQTT topic subscriptions strings
_strMQTTSUBsetpower = '/TOHVAC/SET/PWR'
_strMQTTSUBsettemp = '/TOHVAC/SET/TEMP'
_strMQTTSUBsetctlmode = '/TOHVAC/SET/CTLMODE'
_strMQTTSUBsetopmode = '/TOHVAC/SET/OPMODE'


--Gateway vars
_strUartOnlineMsg = 'VK3/HVAC1/COMMS/READY'
_bWifiConnected = false
-- command terminator ascii line feed, hex 0x0A, dec. 10
_strCmdTerm = '\n'
-- mqtt topic terminator ascii space, hex 0x20, dec. 32
_strTopicTerm = ' '


-- network callback
net.callback(function(event)
	if ((event.interface == "wf") and (event.type == "up")) then
		-- call user callbacks
		if (not (_network_callback_wifi_connected == nil)) then
			_network_callback_wifi_connected()
		end
	elseif ((event.interface == "wf") and (event.type == "down")) then
		-- call user callbacks
		if (not (_network_callback_wifi_disconnected == nil)) then
			_network_callback_wifi_disconnected()
		end
	end
end)

-- when Wi-Fi is connected
_network_callback_wifi_connected = function()
try(
	function()
	    _bWifiConnected = true
		wcBlock.blockStart(9)
		print('Wifi Connection Successful')
		-- publish to MQTT topic '/HVAC1/WIFI'
		try(
			function()
				-- create the MQTT client and connect, if needed
				_mqtt_lock:lock()
				if (_mqtt == nil) then
					_mqtt = mqtt.client(_yourMqttClientId, _yourMqttBrokerUrl, _yourMqttPort, false, nil, false)
					_mqtt:connect(_yourMqttUid,_yourMqttPwd)
				end
				_mqtt_lock:unlock()

				-- publish to topic
				_mqtt:publish(_strMQTTPUBwificonn, 'CONNECTED', mqtt.QOS0)
				wcBlock.blockEnd(5)
			end,
			function(where, line, err, message)
				wcBlock.blockError(5, err, message)
			end
		)

        
		print('MQTT/PUB/WIFI/CONNECTED')
		-- Wifi is started, broadcast to threads that are waiting
	    _eventWifiStarted:broadcast(false)
		
		
		ucRxCharCnt = 0
		rdUartBuffer = ''
		strChr = ''
		while true do
			ucChar = uart.read(uart.UART2, "*c", 10)
			
			--print('got here')
				 
			if nil ~= ucChar then
			    strChar = string.char(ucChar)
			    print('UART RXD: ' .. ucChar .. strChr)
			    
			
			end
			-- Add char to buffer if not NULL
			if nil ~= ucChar then
				-- If '\n' received perse the command
				if strChar == _strCmdTerm then
				    print('got to: Found CMDTERM')
			
				    print('MQTT VALUE:' .. string.sub(rdUartBuffer, firstIndexOf(rdUartBuffer, _strTopicTerm) + 1, #rdUartBuffer - 1) .. ' MQTT TOPIC:' .. string.sub(rdUartBuffer, 1, firstIndexOf(rdUartBuffer, _strTopicTerm)))
					print('UART CMDTERM RXD QTYBYTES: ' .. ucRxCharCnt .. '  Cmd Buffer:' .. rdUartBuffer)
					-- publish to MQTT topic string.sub(rdUartBuffer, 1, 6)
					try(
						function()
							-- create the MQTT client and connect, if needed
							_mqtt_lock:lock()
							if (_mqtt == nil) then
								_mqtt = mqtt.client(_yourMqttClientId, _yourMqttBrokerUrl, _yourMqttPort, false, nil, false)
								_mqtt:connect(_yourMqttUid,_yourMqttPwd)
							end
							_mqtt_lock:unlock()

							-- publish to topic
							_mqtt:publish(string.sub(rdUartBuffer, 1, firstIndexOf(rdUartBuffer, _strTopicTerm)-1),string.sub(rdUartBuffer, firstIndexOf(rdUartBuffer, _strTopicTerm) + 1, #rdUartBuffer), mqtt.QOS0)
							ucRxCharCnt = 0;
							wcBlock.blockEnd(6)
						end,
						function(where, line, err, message)
							wcBlock.blockError(6, err, message)
						end
					)


					-- Clear buffer since we already published payload to MQTT
					for _, i in ipairs(rdUartBuffer) do
						rdUartBuffer = ''
					end
			else
			        --print('got here3')
			
					rdUartBuffer = rdUartBuffer .. strChar
					print('UART ADDED CHAR TO BUFFER: '.. strChar .. ' Qty Bytes: ' .. ucRxCharCnt .. '  Cmd Buffer:' .. rdUartBuffer)
					ucRxCharCnt = ucRxCharCnt + 1
					-- begin: invert digital pin value pio.GPIO0
					try(
						function()
							if ((_pio_GPIO0 == nil) or (_pio_GPIO0 == pio.INPUT)) then
								_pio_GPIO0 = pio.OUTPUT
								pio.pin.setdir(pio.OUTPUT, pio.GPIO0)
								pio.pin.setpull(pio.NOPULL, pio.GPIO0)
							end

							pio.pin.inv(pio.GPIO0)
						end,
						function(where, line, err, message)
							wcBlock.blockError(7, err, message)
						end
					)
					-- end: invert digital pin value pio.GPIO0
				end
			end
			-- begin: invert digital pin value pio.GPIO2
			try(
				function()
					if ((_pio_GPIO2 == nil) or (_pio_GPIO2 == pio.INPUT)) then
						_pio_GPIO2 = pio.OUTPUT
						pio.pin.setdir(pio.OUTPUT, pio.GPIO2)
						pio.pin.setpull(pio.NOPULL, pio.GPIO2)
					end

					pio.pin.inv(pio.GPIO2)
					--print('got inv GPIO2  bWifiCon: ' .. (_bWifiConnected == true and 'TRUE' or 'FALSE')) --_bWifiConnected)
				end,
				function(where, line, err, message)
					wcBlock.blockError(8, err, message)
				end
			)
			-- end: invert digital pin value pio.GPIO2

			-- wait some time
			if ucRxCharCnt == 0 then 
			    tmr.delayms(math.floor(500))
			else
			    tmr.delayms(math.floor(5))
		    end
		end
		wcBlock.blockEnd(9)
	
	end,
	function(where, line, err, message)
		wcBlock.blockError(9, err, message)
	end)

end

-- when Wi-Fi is disconnected
_network_callback_wifi_disconnected = function()
try(
	function()
		wcBlock.blockStart(13)
		while true do
			-- begin: invert digital pin value pio.GPIO2
			try(
				function()
					if ((_pio_GPIO2 == nil) or (_pio_GPIO2 == pio.INPUT)) then
						_pio_GPIO2 = pio.OUTPUT
						pio.pin.setdir(pio.OUTPUT, pio.GPIO2)
						pio.pin.setpull(pio.NOPULL, pio.GPIO2)
					end

					pio.pin.inv(pio.GPIO2)
				end,
				function(where, line, err, message)
					wcBlock.blockError(12, err, message)
				end
			)
			-- end: invert digital pin value pio.GPIO2

			-- wait some time
			tmr.delayms(math.floor(100))
		end
		wcBlock.blockEnd(13)
	end,
	function(where, line, err, message)
		wcBlock.blockError(13, err, message)
	end
)

end

function firstIndexOf(str, substr)
	local i = string.find(str, substr, 1, true)
	if i == nil then
		return 0
	else
		return i
	end
end
-- Describe this function...
function txMQQTtoUART(cmdVal, cmdId)
	txUartBuffer = txUartBuffer .. cmdId .. ' ' .. cmdVal
	try(
		function()
			-- write text
			uart.write(uart.UART2,txUartBuffer)
			txUartBuffer = ""
		end,
		function(where, line, err, message)
			wcBlock.blockError(10, err, message)
		end
	)
end

-- subscribe to MQTT topic _strMQTTSUBsetpower
thread.start(function()
	_eventWifiStarted:wait()

	try(
		function()
		    --if _bWifiConnected == false then
    		  print('Subscribe to: ' .. _strMQTTSUBsetpower .. ' topic' .. '\n')
    		--   return 
		    --end	
		        -- create the MQTT client and connect, if needed
    			_mqtt_lock:lock()
    			if (_mqtt == nil) then
    				_mqtt = mqtt.client(_yourMqttClientId, _yourMqttBrokerUrl, _yourMqttPort, false, nil, false)
    				_mqtt:connect(_yourMqttUid,_yourMqttPwd)
    			end
    			_mqtt_lock:unlock()
    
    			-- subscribe to topic
    			_mqtt:subscribe(_strMQTTSUBsetpower, mqtt.QOS0, function(length, payload)
    				-- a new message is available in length / payload arguments
    				wcBlock.blockStart(11)
    				try(
    					function()
    						txMQQTtoUART(payload, _strMQTTSUBsetpower)
    					end,
    					function(where, line, err, message)
    						wcBlock.blockError(11, err, message)
    					end
    				)
    				wcBlock.blockEnd(11)
    			end)
		end,
		function(where, line, err, message)
			wcBlock.blockError(11, err, message)
		end
	)
end)

-- subscribe to MQTT topic _strMQTTSUBsettemp
thread.start(function()
	_eventWifiStarted:wait()

	try(
		function()
    		--if _bWifiConnected == false then
    		print('Subsribe to:' .. _strMQTTSUBsettemp .. ' topic\n')
    		
    		--   return 
    		--end
    	    -- create the MQTT client and connect, if needed
			_mqtt_lock:lock()
			if (_mqtt == nil) then
				_mqtt = mqtt.client(_yourMqttClientId, _yourMqttBrokerUrl, _yourMqttPort, false, nil, false)
				_mqtt:connect(_yourMqttUid,_yourMqttPwd)
			end
			_mqtt_lock:unlock()

			-- subscribe to topic
			_mqtt:subscribe('/TOHVAC/SET/TEMP', mqtt.QOS0, function(length, payload)
				-- a new message is available in length / payload arguments
				wcBlock.blockStart(14)
				try(
					function()
						txMQQTtoUART(payload, '/TOHVAC/SET/TEMP')
					end,
					function(where, line, err, message)
						wcBlock.blockError(14, err, message)
					end
				)
				wcBlock.blockEnd(14)
			end)
		end,
		function(where, line, err, message)
			wcBlock.blockError(14, err, message)
		end
	)
end)

-- when board starts
thread.start(function()
	wcBlock.blockStart(4)
	try(
		function()
			try(
				function()
					-- attach uart
					uart.attach(uart.UART2,115200,8,uart.PARNONE,1)
				end,
				function(where, line, err, message)
					wcBlock.blockError(1, err, message)
				end
			)

			txUartBuffer = ''
			print('Starting Wifi....')
			try(
				function()
					-- write text
					uart.write(uart.UART2,_strUartOnlineMsg)
				end,
				function(where, line, err, message)
					wcBlock.blockError(2, err, message)
				end
			)

			-- configure wifi and start wifi
			try(
				function()
					wcBlock.blockStart(3)
					print("Attempt Wifi Start   SSID: " .. _yourssid .. " PWD: " .. _yourwifipwd) 
					net.wf.setup(net.wf.mode.STA, _yourssid,_yourwifipwd)
					net.wf.start(false)
					wcBlock.blockEnd(3)
				end,
				function(where, line, err, message)
					wcBlock.blockError(3, err, message)
				end
			)

		end,
		function(where, line, err, message)
			wcBlock.blockError(4, err, message)
		end
	)
	wcBlock.blockEnd(4)

	-- board is started, broadcast to threads that are waiting
	_eventBoardStarted:broadcast(false)
end)
