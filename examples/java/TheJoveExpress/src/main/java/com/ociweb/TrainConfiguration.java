package com.ociweb;

import com.ociweb.gl.api.ArgumentProvider;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.gl.api.TelemetryConfig;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.ActuatorDriverPort;

public class TrainConfiguration  {
    final String trainName;

    final boolean mqttEnabled = true;
    final String mqttBrokerHost;
    final String mqttClientName;
    final int mqttPort = MQTTBridge.defaultPort;

    final boolean telemetryEnabled = true;
    final int telemetryPort = TelemetryConfig.defaultTelemetryPort;
    final String telemetryHost = null;

    final boolean lifecycleEnabled = true;

    boolean sharedAcutatorEnabled = false;
    // Non-shared actuator
    final Port pwmEnginePowerPort = Port.D5;
    final Port pwmEngineDirectionPort = Port.D6;
    final Port ledPort = Port.D3;

    final boolean engineEnabled = true;
    final ActuatorDriverPort engineActuatorPort = ActuatorDriverPort.A;
    final int defaultEngineCalibration;

    final boolean lightsEnabled = true;
    final ActuatorDriverPort lightActuatorPort = ActuatorDriverPort.B;
    final int lightDetectFreq = 250;
    final Port lightSensorPort = Port.A0;
    final boolean simulateLightSensor = true;

    final boolean billboardEnabled = false;
    final String trainDisplayName;

    //final boolean cameraEnabled = false;
    //final String cameraOutputFormat = "/home/pi/pi-cam-test/image-%d.raw"; //where %d is the current timestamp

    final boolean locationEnabled = false;

    final boolean faultDetectionEnabled = true; //NOTE: warning the accelerometer is never found to be publishing if this is on...
    //final int accelerometerReadFreq = 250;

    final boolean appServerEnabled = true;
    final int appServerPort = 8089;
    final String resourceRoot = "joveSite";
    final String resourceDefaultPath = "/index.html"; //used when caller does not provide path

    final boolean soundEnabled = false;

    TrainConfiguration(ArgumentProvider args) {
        // TODO: we need to come up with a better way to customize per train
        this.trainName = args.getArgumentValue("--name", "-n", "thejoveexpress");
        this.mqttBrokerHost = args.getArgumentValue("--broker", "-b", this.trainName + ".local");
        this.mqttClientName = trainName;
        this.trainDisplayName = args.getArgumentValue("--display", "-d", "The Jove Express");
        this.defaultEngineCalibration = args.getArgumentValue("--calibrartion", "-c", 30);
        this.sharedAcutatorEnabled = args.getArgumentValue("--sharedact", "-sa", true);
    }
}
