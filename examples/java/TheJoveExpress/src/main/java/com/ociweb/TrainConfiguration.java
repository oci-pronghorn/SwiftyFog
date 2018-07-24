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

    final boolean faultDetectionEnabled = false; //NOTE: warning the accelerometer is never found to be publishing if this is on...
    final int accelerometerReadFreq = 250;

    final boolean appServerEnabled = false;
    final int appServerPort = 8089;

    final boolean soundEnabled = false;

	final boolean sharedAcutatorEnabled;

	final Port enginePowerPort     = Port.D5; 
	final Port engineDirectionPort = Port.D7;

	final int engineCalibration;

    TrainConfiguration(ArgumentProvider args) {
        // TODO: we need to come up with a better way to customize per train
        this.trainName = args.getArgumentValue("--name", "-n", "thejoveexpress");
        this.mqttBrokerHost = args.getArgumentValue("--broker", "-b", this.trainName + ".local");
        this.mqttClientName = trainName;
        this.trainDisplayName = args.getArgumentValue("--display", "-d", "The Jove Express");
        this.engineCalibration = args.getArgumentValue("--calibrartion", "-c", 30);
        this.sharedAcutatorEnabled = args.getArgumentValue("--sharedact", "-sa", true);
    }
}
