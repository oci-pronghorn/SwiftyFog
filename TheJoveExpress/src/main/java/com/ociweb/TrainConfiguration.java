package com.ociweb;

import com.ociweb.gl.api.ArgumentProvider;
import com.ociweb.iot.maker.TriState;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.iot.maker.Port;

import static com.ociweb.iot.maker.Port.A0;

public class TrainConfiguration  {

    final String trainName;
    final boolean mqttDefaultLocal = false;
    final boolean mqttEnabled = true;
    final String mqttBroker;
    final String mqttClientName;
    final int mqttPort = 1883;
    final TriState telemetryEnabled = TriState.on;
    final boolean lifecycleEnabled = true;
    final boolean engineEnabled = true;
    final boolean lightsEnabled = true;
    final int lightDetectFreq = 250;
    final boolean billboardEnabled = true;
    final boolean cameraEnabled = false;
    final boolean soundEnabled = false;
    final boolean speedometerEnabled = false;
    final boolean appServerEnabled = false;
    final int appServerPort = 8089;

    final Port lightSensorPort = A0;
    final ActuatorDriverPort engineAccuatorPort = ActuatorDriverPort.A;
    final ActuatorDriverPort lightAccuatorPort = ActuatorDriverPort.B;

    TrainConfiguration(ArgumentProvider args) {
        this.trainName = args.getArgumentValue("--name", "-n", "thejoveexpress");
        String defaultBroker = mqttDefaultLocal ? "localhost" : this.trainName + ".local";
        this.mqttBroker = args.getArgumentValue("--broker", "-b", defaultBroker);
        this.mqttClientName = trainName;
    }
}
