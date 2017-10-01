package com.ociweb;

import com.ociweb.behaviors.*;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.gl.api.MQTTConnectionFeedback;
import com.ociweb.gl.api.MQTTQoS;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
import com.ociweb.iot.grove.six_axis_accelerometer.SixAxisAccelerometerTwig;
import com.ociweb.iot.maker.*;
import com.ociweb.model.PubSub;
import com.ociweb.pronghorn.iot.i2c.I2CJFFIStage;

import static com.ociweb.iot.grove.motor_driver.MotorDriverTwig.MotorDriver;
import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_96x96;

public class TheJoveExpress implements FogApp
{
    private TrainConfiguration config;
    private MQTTBridge mqttBridge;

    @Override
    public void declareConnections(Hardware c) {
        config = new TrainConfiguration(c);

        I2CJFFIStage.debugCommands = false;

        // TODO: calculating maxMessageLength anf maxinFlight given the private channel definitions and arbitrary bridging
        // is too difficult. And we are declaring this in connections where channel message lengths are in behavior
        if (config.mqttEnabled) {
            this.mqttBridge = c.useMQTT(config.mqttBroker, config.mqttPort, false, config.mqttClientName, 40, 20000)
                    .cleanSession(true)
                    .authentication("dsjove", "password")
                    .keepAliveSeconds(10);
        }
        if (config.appServerEnabled) c.enableServer(false, config.appServerPort); // TODO: heap problem on Pi0
        if (config.lightsEnabled) c.connect(SimpleAnalogTwig.LightSensor, config.lightSensorPort, config.lightDetectFreq);
        if (config.soundEnabled) c.useSerial(Baud.B_____9600);
        if (config.engineEnabled || config.lightsEnabled) c.connect(MotorDriver);
        if (config.billboardEnabled) c.connect(OLED_96x96);
        if (config.speedometerEnabled) {
            c.connect(SixAxisAccelerometerTwig.SixAxisAccelerometer.readAccel, 1000);
            // c.connect(invisible light reflective change sensor);
        }
        if (config.cameraEnabled) ; //c.connect(pi-bus camera);
        if (config.soundEnabled) ; //c.connect(serial mp3 player);

        // TODO: move this logic into Hardware
        switch (config.telemetryEnabled) {
            case on:
                if (config.telemetryHost != null) {
                    c.enableTelemetry(config.telemetryHost, Hardware.defaultTelemetryPort);
                }
                else {
                    c.enableTelemetry();
                }
                break;
            case latent:
                if (c.isTestHardware()) {
                    if (config.telemetryHost != null) {
                        c.enableTelemetry(config.telemetryHost, Hardware.defaultTelemetryPort);
                    }
                    else {
                        c.enableTelemetry();
                    }
                }
                break;
        }

        //c.setTimerPulseRate(1000);
    }

    // TODO: Test
    /*
    public void declareBehavior2(FogRuntime runtime) {
        PubSub pubSub = new PubSub(config.trainName, runtime, config.mqttEnabled ? mqttBridge : null);

        if (config.lifecycleEnabled) {
            final String lifeCycleFeedback = "lifecycle/feedback";
            final String internalMqttConnect = "MQTT/Connection";
            final String shutdownControl = "lifecycle/control/shutdown";
            pubSub.lastWill(lifeCycleFeedback, true, MQTTQoS.atLeastOnce, blobWriter -> { blobWriter.writeBoolean(false); }); // TODO remove immutable check
            pubSub.connectionFeedbackTopic(internalMqttConnect);
            LifeCycleBehavior lifeCycle = new LifeCycleBehavior(runtime,
                    pubSub.publish(lifeCycleFeedback, true, MQTTQoS.atLeastOnce));
            pubSub.subscribe(lifeCycle, internalMqttConnect, MQTTQoS.atLeastOnce, lifeCycle::onMQTTConnect);
            pubSub.subscribe(lifeCycle, shutdownControl, MQTTQoS.atMostOnce, lifeCycle::onShutdown);
        }

        final String allFeedback = "feedback";

        if (config.engineEnabled || config.lightsEnabled) {
            final String actuatorPowerInternal = "actuator/power/internal";

            final ActuatorDriverBehavior actuator = new ActuatorDriverBehavior(runtime);
            runtime.registerListener(actuator)
                    .addSubscription(actuatorPowerInternal, actuator::setPower);

            if (config.engineEnabled) {
                final EngineBehavior engine = new EngineBehavior(runtime, actuatorPowerInternal, config.engineAccuatorPort,
                        pubSub.publish("engine/power/feedback", false, MQTTQoS.atMostOnce),
                        pubSub.publish("engine/calibration/feedback", false, MQTTQoS.atMostOnce));
                pubSub.subscribe(engine, allFeedback, MQTTQoS.atMostOnce, engine::onAllFeedback);
                pubSub.subscribe(engine,"engine/power/control", MQTTQoS.atMostOnce, engine::onPower);
                pubSub.subscribe(engine,"engine/calibration/control", MQTTQoS.atMostOnce, engine::onCalibration);
            }

            if (config.lightsEnabled) {
                final String lightsAmbientFeedback = "lights/ambient/feedback";
                final AmbientLightBehavior ambientLight = new AmbientLightBehavior(runtime, config.lightSensorPort,
                        pubSub.publish(lightsAmbientFeedback, false, MQTTQoS.atMostOnce));
                pubSub.subscribe(ambientLight, allFeedback, MQTTQoS.atMostOnce, ambientLight::onAllFeedback);

                final LightingBehavior lights = new LightingBehavior(runtime, actuatorPowerInternal, config.lightAccuatorPort,
                        pubSub.publish("lights/override/feedback", false, MQTTQoS.atMostOnce),
                        pubSub.publish("lights/power/feedback", false, MQTTQoS.atMostOnce),
                        pubSub.publish("lights/calibration/feedback", false, MQTTQoS.atMostOnce));
                pubSub.subscribe(lights, allFeedback, MQTTQoS.atMostOnce, lights::onAllFeedback);
                pubSub.subscribe(lights,"lights/override/control", MQTTQoS.atMostOnce, lights::onOverride);
                pubSub.subscribe(lights,"lights/calibration/control", MQTTQoS.atMostOnce, lights::onCalibration);
                pubSub.subscribe(lights, lightsAmbientFeedback, lights::onDetected);
            }

            if (config.billboardEnabled) {
                final BillboardBehavior billboard = new BillboardBehavior(runtime,
                        pubSub.publish("billboard/spec/feedback", true, MQTTQoS.atMostOnce));
                pubSub.subscribe(billboard, allFeedback, MQTTQoS.atMostOnce, billboard::onAllFeedback);
                pubSub.subscribe(billboard, "billboard/image/control", MQTTQoS.atMostOnce, billboard::onImage);
            }

            if (config.speedometerEnabled) {
                final AccelerometerBehavior accelerometer = new AccelerometerBehavior(runtime,
                        pubSub.publish("accelerometer/feedback", false, MQTTQoS.atMostOnce));
                pubSub.registerBehavior(accelerometer);
            }

            if (config.cameraEnabled) {
                // mqtt inbound to take picture
                // save for web app server
                // runtime.registerListener(new CameraBehavior(runtime));
            }

            if (config.soundEnabled) {
                final String soundPiezoControl = "sound/piezo/control";
                final SoundBehavior sound = new SoundBehavior(runtime, config.piezoPort);
                if (config.mqttEnabled) {
                    runtime.bridgeSubscription(soundPiezoControl, prefix + soundPiezoControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                }
                runtime.registerListener(sound)
                        .addSubscription(soundPiezoControl, sound::onLevel);
                // MQTT outbound with sound file listing
                // MQTT outbound with play status
                // MQTT inbound with play/stop/pause commands
                // runtime.registerListener(new SoundBehavior(runtime));
            }
        }

        if (config.appServerEnabled) {
            runtime.addFileServer("").includeAllRoutes(); // TODO: use resource folder
        }

        pubSub.finish();
    }
*/

    @Override
    public void declareBehavior(FogRuntime runtime) {
        // Topics
        final String prefix = config.trainName + "/";
        final String allFeedback = "feedback";
        final String actuatorPowerInternal = "actuator/power/internal";

        // All transient transmissions should have no retain to enforce feedbackloop with UI
        // Schema defining lifecycle transmissions and should have retain

        if (config.lifecycleEnabled) {
            final String lifeCycleFeedback = "lifecycle/feedback";
            final String shutdownControl = "lifecycle/control/shutdown";
            final String internalMqttConnect = "MQTT/Connection";

            // TODO: Last will must be called befor the first bridge call - the makes it immutable
            // We need to make this logic simpler to implement
            if (config.mqttEnabled) {
                this.mqttBridge.lastWill(prefix + lifeCycleFeedback, true, MQTTQoS.atLeastOnce, blobWriter -> { blobWriter.writeBoolean(false); });
                this.mqttBridge.connectionFeedbackTopic(internalMqttConnect);
                runtime.bridgeTransmission(lifeCycleFeedback, prefix + lifeCycleFeedback, mqttBridge).setRetain(true).setQoS(MQTTQoS.atLeastOnce);
                runtime.bridgeSubscription(shutdownControl, prefix + shutdownControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
            }
            LifeCycleBehavior lifeCycle = new LifeCycleBehavior(runtime, lifeCycleFeedback);
            runtime.registerListener(lifeCycle)
                    .addSubscription(internalMqttConnect, lifeCycle::onMQTTConnect)
                    .addSubscription(shutdownControl, lifeCycle::onShutdown);
        }

        if (config.mqttEnabled) {
            runtime.bridgeSubscription(allFeedback, prefix + allFeedback, mqttBridge).setQoS(MQTTQoS.atLeastOnce);
        }

        if (config.appServerEnabled) {
            runtime.addFileServer("").includeAllRoutes(); // TODO: use resource folder
        }

        if (config.engineEnabled || config.lightsEnabled) {
            final ActuatorDriverBehavior actuator = new ActuatorDriverBehavior(runtime);
            runtime.registerListener(actuator)
                    .addSubscription(actuatorPowerInternal, actuator::setPower);
        }

        if (config.engineEnabled) {
            final String enginePowerControl = "engine/power/control";
            final String engineCalibrationControl = "engine/calibration/control";
            final String enginePowerFeedback = "engine/power/feedback";
            final String engineCalibrationFeedback = "engine/calibration/feedback";

            if (config.mqttEnabled) {
                runtime.bridgeSubscription(enginePowerControl, prefix + enginePowerControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeSubscription(engineCalibrationControl, prefix + engineCalibrationControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeTransmission(enginePowerFeedback, prefix + enginePowerFeedback, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeTransmission(engineCalibrationFeedback, prefix + engineCalibrationFeedback, mqttBridge).setQoS(MQTTQoS.atMostOnce);
            }
            final EngineBehavior engine = new EngineBehavior(runtime, actuatorPowerInternal, config.engineAccuatorPort, enginePowerFeedback, engineCalibrationFeedback);
            runtime.registerListener(engine)
                    .addSubscription(allFeedback, engine::onAllFeedback)
                    .addSubscription(enginePowerControl, engine::onPower)
                    .addSubscription(engineCalibrationControl, engine::onCalibration);
        }

        if (config.lightsEnabled) {
            final String lightsOverrideControl = "lights/override/control";
            final String lightsCalibrationControl = "lights/calibration/control";
            final String lightsOverrideFeedback = "lights/override/feedback";
            final String lightsPowerFeedback = "lights/power/feedback";
            final String lightsCalibrationFeedback = "lights/calibration/feedback";
            final String lightsAmbientFeedback = "lights/ambient/feedback";

            if (config.mqttEnabled) {
                runtime.bridgeSubscription(lightsOverrideControl, prefix + lightsOverrideControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeSubscription(lightsCalibrationControl, prefix + lightsCalibrationControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeTransmission(lightsOverrideFeedback, prefix + lightsOverrideFeedback, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeTransmission(lightsPowerFeedback, prefix + lightsPowerFeedback, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeTransmission(lightsCalibrationFeedback, prefix + lightsCalibrationFeedback, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeTransmission(lightsAmbientFeedback, prefix + lightsAmbientFeedback, mqttBridge).setQoS(MQTTQoS.atMostOnce);
            }
            final AmbientLightBehavior ambientLight = new AmbientLightBehavior(runtime, config.lightSensorPort, lightsAmbientFeedback);
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
            final String accelerometerPublishTopic = "accelerometer";

            if (config.mqttEnabled) {
                runtime.bridgeTransmission(accelerometerPublishTopic, prefix + accelerometerPublishTopic, mqttBridge).setQoS(MQTTQoS.atMostOnce);
            }
            final AccelerometerBehavior accelerometer = new AccelerometerBehavior(runtime, accelerometerPublishTopic);
            runtime.registerListener(accelerometer);
        }

        if (config.billboardEnabled) {
            final String billboardImageControl = "billboard/image/control";
            final String billboardSpecFeedback = "billboard/spec/feedback";

            if (config.mqttEnabled) {
                runtime.bridgeSubscription(billboardImageControl, prefix + billboardImageControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
                runtime.bridgeTransmission(billboardSpecFeedback, prefix + billboardSpecFeedback, mqttBridge).setQoS(MQTTQoS.atMostOnce);
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
            final String soundPiezoControl = "sound/piezo/control";

            final SoundBehavior sound = new SoundBehavior(runtime, config.piezoPort);
            if (config.mqttEnabled) {
                runtime.bridgeSubscription(soundPiezoControl, prefix + soundPiezoControl, mqttBridge).setQoS(MQTTQoS.atMostOnce);
            }
            runtime.registerListener(sound)
                    .addSubscription(soundPiezoControl, sound::onLevel);

            // MQTT outbound with sound file listing
            // MQTT outbound with play status
            // MQTT inbound with play/stop/pause commands
            // runtime.registerListener(new SoundBehavior(runtime));
        }
    }
}
