package com.ociweb;

import com.ociweb.gl.api.ArgumentProvider;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.gl.api.TelemetryConfig;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.ActuatorDriverPort;

/**
 * This class defines all the configuration variables for the train.
 */
public class TrainConfiguration  {
    // Names
    final String trainDisplayName;
    final String trainName;
    final String topicPrefix; // used for muti-use MQTT brokers and MQTT train auto-discovery

    // MQTT
    final boolean mqttEnabled = true;
    final String mqttBrokerHost;
    final String mqttClientName;
    final int mqttPort;

    // Telemetry
    final boolean telemetryEnabled = true;
    final int telemetryPort = TelemetryConfig.defaultTelemetryPort;
    final String telemetryHost = null;

    // Lifecycle
    final boolean lifecycleEnabled = true;

    // Motor
    final FeatureEnabled engineEnabled = FeatureEnabled.full;
    final ActuatorDriverPort engineActuatorPort = ActuatorDriverPort.A;
    final int defaultEngineCalibration;

    // Lighting
    final FeatureEnabled lightsEnabled = FeatureEnabled.full;
    final ActuatorDriverPort lightActuatorPort = ActuatorDriverPort.B;
    final int lightDetectFreq = 250;
    final Port lightSensorPort = Port.A0;

    // Lighting/Motor Hardware
    final boolean sharedAcutatorEnabled;
    // Non-shared actuator
    final Port pwmEnginePowerPort = Port.D5;
    final Port pwmEngineDirectionPort = Port.D6;
    final Port ledPort = Port.D3;

    // Display (currently Text Display - not Images)
    final FeatureEnabled billboardEnabled = FeatureEnabled.nothing; //TODO: need argument passed in to enable/disable

    // Fault Tracking
    final FeatureEnabled faultTrackingEnabled = FeatureEnabled.nothing; //TODO: needs command line switch, // Hardware not supported yet

    // Web Server
    final boolean appServerEnabled;
    final int appServerPort = 8089;
    final String resourceRoot = "/joveSite";
    final String resourceDefaultPath = "/index.html"; //used when caller does not provide path

    // Camera
    //where the train should post images from the camera
    final String imageCaptureURL;

// Not Implemented

    final int accelerometerReadFreq = 250;

    // Sound
    final boolean soundEnabled = false;

    // Location Detection
    final boolean locationEnabled = false;

// Constructor

    TrainConfiguration(ArgumentProvider args) {
        // TODO: we need to come up with an easier way to customize per train
        this.trainName = args.getArgumentValue("--name", "-n", "thejoveexpress");
        this.mqttBrokerHost = args.getArgumentValue("--broker", "-b", this.trainName + ".local");
        this.mqttClientName = trainName;
        this.trainDisplayName = args.getArgumentValue("--display", "-d", "The Jove Express");
        this.defaultEngineCalibration = args.getArgumentValue("--calibrartion", "-c", 30);
        this.sharedAcutatorEnabled = args.getArgumentValue("--sharedact", "-sa", true);
        this.appServerEnabled = args.getArgumentValue("--webserver", "-w", true);
        this.mqttPort = args.getArgumentValue("--brokerp", "-bp", MQTTBridge.defaultPort);
        this.topicPrefix = args.getArgumentValue("--topicPrefix", "-tp", (String)null);
        this.imageCaptureURL  =  args.getArgumentValue("--imageCaptureURL", "-icURL", (String)null); //URL to post images into
    }
}
