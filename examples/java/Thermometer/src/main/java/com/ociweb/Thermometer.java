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
    
    private final String temperaturePubTopic = "temperature/feedback";
    private final Port temperatureSensorPort = A1;

    @Override
    public void declareConnections(Hardware c) {	
        this.mqttBridge = c.useMQTT("172.16.10.77", 1883, false, "Thermometer-Publisher", 40, 20000)
                .cleanSession(true)
                .keepAliveSeconds(10);
        
        c.connect(SimpleAnalogTwig.LightSensor, temperatureSensorPort);
    }

    @Override
    public void declareBehavior(FogRuntime runtime) {
		runtime.bridgeTransmission(temperaturePubTopic, mqttBridge);
		runtime.registerListener(new TempSensorBehavior(runtime, temperatureSensorPort, temperaturePubTopic));
    }
          
}
