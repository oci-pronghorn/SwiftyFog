package com.ociweb;

import com.ociweb.gl.api.ArgumentProvider;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.iot.maker.Port;

import static com.ociweb.iot.maker.Port.A0;

public class TrainConfiguration  {

    final String trainName;
    final String mqttBroker;
    final String mqttClientName;
    final int mqttPort = 1883;
    final boolean engineEnabled = true;
    final boolean lightsEnabled = true;
    final boolean billboardEnabled = true;
    final boolean cameraEnabled = false;
    final boolean soundEnabled = false;
    final boolean speedometerEnabled = false;
    final boolean appServerEnabled = false;
    final boolean mqttEnabled = true;
    final int appServerPort = 8089;
    final int lightDetectFreq = 250;

    final Port lightSensorPort = A0;
    final ActuatorDriverPort engineAccuatorPort = ActuatorDriverPort.A;
    final ActuatorDriverPort lightAccuatorPort = ActuatorDriverPort.B;

    TrainConfiguration(ArgumentProvider args) {
        this.trainName = args.getArgumentValue("--name", "-n", "thejoveexpress");
        this.mqttBroker = args.getArgumentValue("--broker", "-b", this.trainName + ".local");
        this.mqttClientName = trainName;
    }
}
