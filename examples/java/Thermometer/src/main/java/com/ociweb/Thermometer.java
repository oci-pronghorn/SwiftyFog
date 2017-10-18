package com.ociweb;

import com.ociweb.behaviors.*;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
import com.ociweb.iot.grove.temp_and_humid.TempAndHumidTwig;
import com.ociweb.iot.hardware.I2CIODevice;
import com.ociweb.iot.maker.*;
import static com.ociweb.iot.maker.Port.*;

public class Thermometer implements FogApp
{
    private MQTTBridge mqttBridge;
    
    private final String tempPubTopic = "temperature/feedback";
    private final Port TEMPERATURE_SENSOR_PORT = A1;

    @Override
    public void declareConnections(Hardware c) {	
    		//TODO: Don't hard-code the arguments
        this.mqttBridge = c.useMQTT("tobi.local", 1883, false, "Thermometer-Publisher", 40, 20000)
                .cleanSession(true)
                .keepAliveSeconds(10);
        
        c.connect(SimpleAnalogTwig.LightSensor, TEMPERATURE_SENSOR_PORT);
    }

    @Override
    public void declareBehavior(FogRuntime runtime) {
		runtime.bridgeTransmission(tempPubTopic, mqttBridge);
		runtime.registerListener(new TempSensorBehavior(runtime, TEMPERATURE_SENSOR_PORT, tempPubTopic));
    }
          
}
