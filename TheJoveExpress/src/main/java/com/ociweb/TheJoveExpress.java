package com.ociweb;

import com.ociweb.behaviors.*;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.gl.impl.MQTTQOS;
import com.ociweb.iot.grove.six_axis_accelerometer.SixAxisAccelerometerTwig;
import com.ociweb.iot.maker.*;

import static com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig.*;
import static com.ociweb.iot.grove.motor_driver.MotorDriverTwig.MotorDriver;
import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_96x96;

public class TheJoveExpress implements FogApp
{
    private TrainConfiguration config;
    private MQTTBridge mqttBridge;

    @Override
    public void declareConnections(Hardware c) {
        config = new TrainConfiguration(c);

        final String prefix = config.trainName + "/";
        final String trainAliveFeedback = "alive/feedback";

        // TODO: calculating maxMessageLength anf maxinFlight given the private channel definitions and arbitrary bridging
        // is too difficult. And we are declaring this in connections where channel message lengths are in behavior
        if (config.mqttEnabled) {
            this.mqttBridge = c.useMQTT(config.mqttBroker, config.mqttPort, false, config.mqttClientName, 20, 15000)
                    .cleanSession(true)
                    .authentication("dsjove", "password")
                    .keepAliveSeconds(10);
                    //.will(true, MQTTQOS.atMostOnce, prefix + trainAliveFeedback, blobWriter -> {blobWriter.writeBoolean(false);});
        }
        if (config.appServerEnabled) c.enableServer(false, config.appServerPort); // TODO: heap problem on Pi0
        if (config.lightsEnabled) c.connect(LightSensor, config.lightSensorPort, config.lightDetectFreq);
        if (config.engineEnabled || config.lightsEnabled) c.connect(MotorDriver);
        if (config.billboardEnabled) c.connect(OLED_96x96);
        if (config.speedometerEnabled) {
            c.connect(SixAxisAccelerometerTwig.SixAxisAccelerometer.readAccel, 1000);
            // c.connect(invisible light reflective change sensor);
        }
        if (config.cameraEnabled) ; //c.connect(pi-bus camera);
        if (config.soundEnabled) ; //c.connect(serial mp3 player);

        switch (config.telemetryEnabled) {
            case on:
                c.enableTelemetry();
                break;
            case latent:
                if (c.isTestHardware()) c.enableTelemetry();
                break;
        }

        //c.setTimerPulseRate(1000);
    }

    @Override
    public void declareBehavior(FogRuntime runtime) {
        // Topics
        final String prefix = config.trainName + "/";

        final String trainAliveFeedback = "alive/feedback";

        final String actuatorPowerInternal = "actuator/power/internal";

        final String enginePowerControl = "engine/power/control";
        final String engineCalibrationControl = "engine/calibration/control";
        final String enginePowerFeedback = "engine/power/feedback";
        final String engineCalibrationFeedback = "engine/calibration/feedback";

        final String lightsOverrideControl = "lights/override/control";
        final String lightsCalibrationControl = "lights/calibration/control";
        final String lightsOverrideFeedback = "lights/override/feedback";
        final String lightsPowerFeedback = "lights/power/feedback";
        final String lightsCalibrationFeedback = "lights/calibration/feedback";
        final String lightsAmbientFeedback = "lights/ambient/feedback";

        final String billboardImageControl = "billboard/image/control";
        final String billboardSpecFeedback = "billboard/spec/feedback";

        final String accelerometerPublishTopic = "accelerometer";

        final String allFeedback = "feedback";
        if (config.mqttEnabled) {
            runtime.bridgeSubscription(allFeedback, prefix + allFeedback, mqttBridge).setQoS(MQTTQOS.atLeastOnce);
        }

        // TODO: all inbound have the train name wildcard topic

        // All transient transmissions should have retain no retain to enforce feedbackloop with UI
        // Schema defining transmissions should have retain

        if (config.appServerEnabled) {
            runtime.addFileServer("").includeAllRoutes(); // TODO: use resource folder
        }

        if (config.engineEnabled || config.lightsEnabled) {
            final ActuatorDriverBehavior actuator = new ActuatorDriverBehavior(runtime);
            runtime.registerListener(actuator)
                    .addSubscription(actuatorPowerInternal, actuator::setPower);
        }

        if (config.engineEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeSubscription(enginePowerControl, prefix + enginePowerControl, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeSubscription(engineCalibrationControl, prefix + engineCalibrationControl, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(enginePowerFeedback, prefix + enginePowerFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(engineCalibrationFeedback, prefix + engineCalibrationFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce);
            }
            final EngineBehavior engine = new EngineBehavior(runtime, actuatorPowerInternal, config.engineAccuatorPort, enginePowerFeedback, engineCalibrationFeedback);
            runtime.registerListener(engine)
                    .addSubscription(allFeedback, engine::onAllFeedback)
                    .addSubscription(enginePowerControl, engine::onPower)
                    .addSubscription(engineCalibrationControl, engine::onCalibration);
        }

        if (config.lightsEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeSubscription(lightsOverrideControl, prefix + lightsOverrideControl, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeSubscription(lightsCalibrationControl, prefix + lightsCalibrationControl, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(lightsOverrideFeedback, prefix + lightsOverrideFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(lightsPowerFeedback, prefix + lightsPowerFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(lightsCalibrationFeedback, prefix + lightsCalibrationFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(lightsAmbientFeedback, prefix + lightsAmbientFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce);
            }
            final AmbientLightBroadcast ambientLight = new AmbientLightBroadcast(runtime, config.lightSensorPort, lightsAmbientFeedback);
            runtime.registerListener(ambientLight)
                    .addSubscription(allFeedback, ambientLight::onAllFeedback);
            final LightingBehavior lights = new LightingBehavior(runtime, actuatorPowerInternal, config.lightAccuatorPort, lightsOverrideFeedback, lightsPowerFeedback, lightsCalibrationFeedback);
            runtime.registerListener(lights)
                    .addSubscription(allFeedback, lights::onAllFeedback)
                    .addSubscription(lightsOverrideControl, lights::onOverride)
                    .addSubscription(lightsCalibrationControl, lights::onCalibration)
                    .addSubscription(lightsAmbientFeedback, lights::onDetected);
        }

        if (config.speedometerEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeTransmission(accelerometerPublishTopic, prefix + accelerometerPublishTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce);
            }
            final AccelerometerBehavior accelerometer = new AccelerometerBehavior(runtime, accelerometerPublishTopic);
            runtime.registerListener(accelerometer);
            //runtime.registerListener(new RailTieSensingBehavior(runtime));
        }

        if (config.billboardEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeSubscription(billboardImageControl, prefix + billboardImageControl, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(billboardSpecFeedback, prefix + billboardSpecFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce);
            }
            final BillboardBehavior billboard = new BillboardBehavior(runtime, billboardSpecFeedback);
            runtime.registerListener(billboard)
                    .addSubscription(allFeedback, billboard::onAllFeedback)
                    .addSubscription(billboardImageControl, billboard::onImage);
        }

        if (config.cameraEnabled) {
            // mqtt inbound to take picture
            // save for web app server
            // runtime.registerListener(new CameraBehavior(runtime));
        }

        if (config.soundEnabled) {
            // MQTT outbound with sound file listing
            // MQTT outbound with play status
            // MQTT inbound with play/stop/pause commands
            // runtime.registerListener(new SoundBehavior(runtime));
        }

        // firstWill
        runtime.bridgeTransmission(trainAliveFeedback, prefix + trainAliveFeedback, mqttBridge).setQoS(MQTTQOS.atMostOnce).setRetain(true);
        runtime.addStartupListener(new StartupListener() {
            final FogCommandChannel channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
            @Override
            public void startup() {
                //channel.publishTopic( trainAliveFeedback, blobWriter -> {blobWriter.writeBoolean(true);});
            }
        });
    }
}
