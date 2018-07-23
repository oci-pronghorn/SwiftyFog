package com.ociweb;

import com.ociweb.gl.api.ArgumentProvider;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.ActuatorDriverPort;

public class TrainConfiguration  {
    final String trainName;

    final boolean mqttEnabled = true;
    final String mqttBrokerHost;
    final String mqttClientName;
    final int mqttPort = 1883;

    final boolean telemetryEnabled = true;
    final int telemetryPort = 8089;
    final String telemetryHost = null;

    final boolean lifecycleEnabled = true;

    final boolean engineEnabled = true;
    final ActuatorDriverPort engineActuatorPort = ActuatorDriverPort.A;

    final boolean lightsEnabled = true;
    final int lightDetectFreq = 250;
    final Port lightSensorPort = Port.A0;
    final Port ledPort = Port.D3;
    final ActuatorDriverPort lightActuatorPort = ActuatorDriverPort.B;

    final boolean billboardEnabled = true;
    final String trainDisplayName;

    //final boolean cameraEnabled = false;
    //final String cameraOutputFormat = "/home/pi/pi-cam-test/image-%d.raw"; //where %d is the current timestamp

    final boolean locationEnabled = false;

    final boolean faultDetectionEnabled = true;
    final int accelerometerReadFreq = 250;

    final boolean appServerEnabled = false;
    final int appServerPort = 8089;

    final boolean soundEnabled = false;

    TrainConfiguration(ArgumentProvider args) {
        this.trainName = args.getArgumentValue("--name", "-n", "thejoveexpress");
        this.mqttBrokerHost = args.getArgumentValue("--broker", "-b", this.trainName + ".local");
        this.mqttClientName = trainName;
        this.trainDisplayName = args.getArgumentValue("--display", "-d", "The Jove Express");
    }
}
