package com.ociweb;

import com.ociweb.behaviors.*;
import com.ociweb.behaviors.internal.ActuatorDriverBehavior;
import com.ociweb.behaviors.location.LocationBehavior;
import com.ociweb.behaviors.location.TrainingBehavior;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.gl.api.MQTTQoS;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
import com.ociweb.iot.grove.simple_digital.SimpleDigitalTwig;
import com.ociweb.iot.maker.Baud;
import com.ociweb.iot.maker.FogApp;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.pronghorn.iot.i2c.I2CJFFIStage;
import com.ociweb.pronghorn.stage.scheduling.GraphManager;

import static com.ociweb.iot.grove.motor_driver.MotorDriverTwig.MotorDriver;
import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_128x64;

public class TheJoveExpress implements FogApp
{
    private TrainConfiguration config;
    private MQTTBridge mqttBridge;

    @Override
    public void declareConnections(Hardware hardware) {
        config = new TrainConfiguration(hardware);
        
        hardware.setDefaultRate(16_000_000);

        //hardware.setTestImageSource(Paths.get("source_img"));
        //hardware.useI2C();

        GraphManager.showThreadIdOnTelemetry = true;
        I2CJFFIStage.debugCommands = false;

        if (config.mqttEnabled) {
            this.mqttBridge = hardware.useMQTT(config.mqttBrokerHost, config.mqttPort, config.mqttClientName, 40, 8000)
                    .cleanSession(true)
                    .keepAliveSeconds(10);
            //hardware.definePrivateTopic("", "CameraBehavior", "");
        }
        if (config.appServerEnabled) hardware.useHTTP1xServer(config.appServerPort); // TODO: heap problem on Pi0
        if (config.lightsEnabled) {
            hardware.connect(SimpleAnalogTwig.LightSensor, config.lightSensorPort, config.lightDetectFreq);
            hardware.connect(SimpleDigitalTwig.LED, config.ledPort);
        }
        if (config.soundEnabled) hardware.useSerial(Baud.B_____9600);
        if (config.engineEnabled || config.lightsEnabled) hardware.connect(MotorDriver);
        if (config.billboardEnabled) hardware.connect(OLED_128x64);/*c.connect(OLED_96x96);*/
 //       if (config.faultDetectionEnabled) hardware.connect(SixAxisAccelerometerTwig.SixAxisAccelerometer.readAccel, config.accelerometerReadFreq);
        if (config.soundEnabled) ; //c.connect(serial mp3 player);

        if (config.telemetryEnabled) {
            hardware.enableTelemetry(config.telemetryHost);
        }

        if (config.lightsEnabled) {
            hardware.setTimerPulseRate(1000);
        }
    }

    public void declareBehavior(FogRuntime runtime) {
        TopicJunctionBox pubSub = new TopicJunctionBox(config.trainName, runtime, config.mqttEnabled ? mqttBridge : null);

        if (config.lifecycleEnabled) {
            final String lifeCycleFeedback = "lifecycle/feedback";
            final String internalMqttConnect = "MQTT/Connection";
            final String shutdownControl = "lifecycle/control/shutdown";
            pubSub.lastWill(lifeCycleFeedback, true, MQTTQoS.atLeastOnce, blobWriter -> blobWriter.writeBoolean(false)); // TODO remove immutable check
            pubSub.connectionFeedbackTopic(internalMqttConnect);
            LifeCycleBehavior lifeCycle = new LifeCycleBehavior(runtime,
                    pubSub.publish(lifeCycleFeedback, true, MQTTQoS.atLeastOnce));
            pubSub.subscribe(lifeCycle, internalMqttConnect, MQTTQoS.atLeastOnce, lifeCycle::onMQTTConnect);
            pubSub.subscribe(lifeCycle, shutdownControl, MQTTQoS.atMostOnce, lifeCycle::onShutdown);
        }

        final String allFeedback = "feedback";
        final String accelerometerInternal = "accelerometer/internal";
        final String engineState = "engine/state/feedback";
        final String faultFeedback = "fault/feedback";
        final String lightsPowerFeedback = "lights/power/feedback";

        if (config.engineEnabled || config.lightsEnabled) {
            final String actuatorPowerAInternal = "actuator/power/a/internal";
            final String actuatorPowerBInternal = "actuator/power/b/internal";
            
            final ActuatorDriverBehavior actuator = new ActuatorDriverBehavior(runtime);
            pubSub.subscribe(actuator, actuatorPowerAInternal, actuator::setPower);
            pubSub.subscribe(actuator, actuatorPowerBInternal, actuator::setPower);
            
            if (config.engineEnabled) {
                final EngineBehavior engine = new EngineBehavior(runtime, actuatorPowerAInternal, config.engineActuatorPort,
                        pubSub.publish("engine/power/feedback", false, MQTTQoS.atMostOnce),
                        pubSub.publish("engine/calibration/feedback", false, MQTTQoS.atMostOnce),
                        pubSub.publish("engine/state/feedback", false, MQTTQoS.atMostOnce));
                pubSub.subscribe(engine, allFeedback, MQTTQoS.atMostOnce, engine::onAllFeedback);
                pubSub.subscribe(engine, "engine/power/control", MQTTQoS.atMostOnce, engine::onPower);
                pubSub.subscribe(engine, "engine/calibration/control", MQTTQoS.atMostOnce, engine::onCalibration);
                if (config.faultDetectionEnabled) {
                	pubSub.subscribe(engine, faultFeedback, engine::onFault);
                }
            }

            if (config.lightsEnabled) {
                final String lightsAmbientFeedback = "lights/ambient/feedback";
                final AmbientLightBehavior ambientLight = new AmbientLightBehavior(runtime, config.lightSensorPort,
                        pubSub.publish(lightsAmbientFeedback, false, MQTTQoS.atMostOnce));
                pubSub.subscribe(ambientLight, allFeedback, MQTTQoS.atMostOnce, ambientLight::onAllFeedback);

                final LightingBehavior lights = new LightingBehavior(runtime, actuatorPowerBInternal, config.lightActuatorPort, config.ledPort,
                        pubSub.publish("lights/override/feedback", false, MQTTQoS.atMostOnce),
                        pubSub.publish(lightsPowerFeedback, false, MQTTQoS.atMostOnce),
                        pubSub.publish("lights/calibration/feedback", false, MQTTQoS.atMostOnce));
                pubSub.subscribe(lights, allFeedback, MQTTQoS.atMostOnce, lights::onAllFeedback);
                pubSub.subscribe(lights, "lights/override/control", MQTTQoS.atMostOnce, lights::onOverride);
                pubSub.subscribe(lights, "lights/calibration/control", MQTTQoS.atMostOnce, lights::onCalibration);
                pubSub.subscribe(lights, lightsAmbientFeedback, lights::onDetected);
            }
        }
        if (config.faultDetectionEnabled) {
//            final AccelerometerBehavior accelerometerBehavior = new AccelerometerBehavior(runtime, accelerometerInternal);
//            pubSub.registerBehavior(accelerometerBehavior);
        }

        if (config.faultDetectionEnabled) {
            final MotionFaultBehavior motionFault = new MotionFaultBehavior(runtime,
                    pubSub.publish(faultFeedback, false, MQTTQoS.atMostOnce));
            pubSub.subscribe(motionFault, allFeedback, MQTTQoS.atMostOnce, motionFault::onAllFeedback);
            pubSub.subscribe(motionFault, "fault/control", MQTTQoS.atMostOnce, motionFault::onForceFault);
            pubSub.subscribe(motionFault, accelerometerInternal, motionFault::onAccelerometer);
            pubSub.subscribe(motionFault, engineState, motionFault::onEngineState);
        }

        if (config.billboardEnabled) {
            final TextDisplay billboard = new TextDisplay(runtime, config.trainDisplayName,
                    pubSub.publish("billboard/text/feedback", false, MQTTQoS.atMostOnce));
            pubSub.subscribe(billboard, allFeedback, MQTTQoS.atMostOnce, billboard::onAllFeedback);
            pubSub.subscribe(billboard, "billboard/text/control", MQTTQoS.atMostOnce, billboard::onText);
            pubSub.subscribe(billboard, lightsPowerFeedback, billboard::onLightsPower);
        }

        if(config.locationEnabled) {
            final String locationFeedback = "location/feedback";
            final String accuracyFeedback = "location/accuracy/feedback";

            final TrainingBehavior training = new TrainingBehavior(runtime);
            pubSub.subscribe(training, "location/training/start", MQTTQoS.atLeastOnce, training::onTrainingStart);

            final LocationBehavior location = new LocationBehavior(runtime,
                    pubSub.publish(locationFeedback, false, MQTTQoS.atMostOnce),
                    pubSub.publish(accuracyFeedback, false, MQTTQoS.atMostOnce));
            runtime.registerListener(location);
        }

        if (config.appServerEnabled) {
            runtime.addFileServer("").includeAllRoutes(); // TODO: use resource folder
        }

        pubSub.finish();
    }
}
