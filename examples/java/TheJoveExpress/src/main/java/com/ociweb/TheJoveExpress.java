package com.ociweb;

import com.ociweb.behaviors.*;
import com.ociweb.behaviors.inprogress.AccelerometerBehavior;
import com.ociweb.behaviors.inprogress.LocationBehavior;
import com.ociweb.behaviors.inprogress.TrainingBehavior;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.gl.api.MQTTQoS;
import com.ociweb.iot.maker.FogApp;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.pronghorn.iot.i2c.I2CJFFIStage;
import com.ociweb.pronghorn.stage.scheduling.GraphManager;

/**
 * The main application registers all the hardware and business logic classes.
 */
public class TheJoveExpress implements FogApp
{
    private TrainConfiguration config;
    private MQTTBridge mqttBridge;

    @Override
    public void declareConnections(Hardware hardware) {
        config = new TrainConfiguration(hardware);
        
        hardware.setDefaultRate(16_000_000);

        GraphManager.showThreadIdOnTelemetry = true;
        I2CJFFIStage.debugCommands = false;

        if (config.telemetryEnabled) {
            hardware.enableTelemetry(config.telemetryHost, config.telemetryPort);
        }

        if (config.mqttEnabled) {
            this.mqttBridge = hardware.useMQTT(config.mqttBrokerHost, config.mqttPort, config.mqttClientName, 40, 8000)
                    .cleanSession(true)
                    .keepAliveSeconds(10);
        }

        WebHostBehavior.configure(hardware, config.appServerEnabled, config.appServerPort);

        AmbientLightBehavior.configure(hardware, config.lightsEnabled, config.lightSensorPort, config.lightDetectFreq);

        if (config.lightsEnabled != FeatureEnabled.nothing) {
            hardware.setTimerPulseRate(1000); // needed for startup flash - is there a better way?
        }

        TextDisplayBehavior.configure(hardware, config.billboardEnabled);

        AccelerometerBehavior.configure(hardware, config.faultTrackingEnabled, config.accelerometerReadFreq);

        if (config.sharedAcutatorEnabled) {
            SharedActuatorDriverBehavior.configure(hardware,config.lightsEnabled, config.engineEnabled)    ;
        } else {
            PWMActuatorDriverBehavior.configure(hardware,
                    config.engineEnabled == FeatureEnabled.full ? config.pwmEnginePowerPort : null,
                    config.engineEnabled == FeatureEnabled.full ? config.pwmEngineDirectionPort : null,
                    config.lightsEnabled == FeatureEnabled.full ? config.ledPort : null);
        }

        //if (config.soundEnabled) hardware.useSerial(Baud.B_____9600);
        //if (config.soundEnabled) ; //c.connect(serial mp3 player);
    }

    public void declareBehavior(FogRuntime runtime) {
        TopicJunctionBox topics = new TopicJunctionBox(config.trainName, runtime, config.mqttEnabled ? mqttBridge : null);

        if (config.lifecycleEnabled) {
            // TODO: better encapsulate this logic
            final String lifeCycleFeedback = "lifecycle/feedback";
            final String internalMqttConnect = "MQTT/Connection";
            final String shutdownControl = "lifecycle/control/shutdown";
            topics.lastWill(lifeCycleFeedback, true, MQTTQoS.atLeastOnce, blobWriter -> blobWriter.writeBoolean(false)); // TODO remove immutable check
            topics.connectionFeedbackTopic(internalMqttConnect);
            LifeCycleBehavior lifeCycle = new LifeCycleBehavior(runtime, config.trainDisplayName,
                    topics.publish(lifeCycleFeedback, true, MQTTQoS.atLeastOnce));
            topics.subscribe(lifeCycle, internalMqttConnect, MQTTQoS.atLeastOnce, lifeCycle::onMQTTConnect);
            topics.subscribe(lifeCycle, shutdownControl, MQTTQoS.atMostOnce, lifeCycle::onShutdown);
        }

        final String allFeedback = "feedback";
        final String accelerometerInternal = "accelerometer/internal";
        final String engineState = "engine/state/feedback";
        final String faultFeedback = "fault/feedback";
        final String lightsPowerFeedback = "lights/power/feedback";

        if (config.engineEnabled != FeatureEnabled.nothing || config.lightsEnabled != FeatureEnabled.nothing) {
            final String actuatorPowerAInternal = "actuator/power/a/internal";
            final String actuatorPowerBInternal = "actuator/power/b/internal";
            
            if (config.sharedAcutatorEnabled) {
            	final SharedActuatorDriverBehavior actuator = new SharedActuatorDriverBehavior(runtime);
            	topics.subscribe(actuator, actuatorPowerAInternal, actuator::setPower);
            	topics.subscribe(actuator, actuatorPowerBInternal, actuator::setPower);
            }
            else {
                final PWMActuatorDriverBehavior actuator = new PWMActuatorDriverBehavior(runtime, config.engineActuatorPort);
                topics.subscribe(actuator, actuatorPowerAInternal, actuator::setPower);
                topics.subscribe(actuator, actuatorPowerBInternal, actuator::setPower);
            }

            if (config.engineEnabled != FeatureEnabled.nothing) {
                final EngineBehavior engine = new EngineBehavior(runtime, config.defaultEngineCalibration, actuatorPowerAInternal, config.engineActuatorPort,
                        topics.publish("engine/power/feedback", false, MQTTQoS.atMostOnce),
                        topics.publish("engine/calibration/feedback", false, MQTTQoS.atMostOnce),
                        topics.publish("engine/state/feedback", false, MQTTQoS.atMostOnce));

                topics.subscribe(engine, allFeedback, MQTTQoS.atMostOnce, engine::onAllFeedback);
                topics.subscribe(engine, "engine/power/control", MQTTQoS.atMostOnce, engine::onPower);
                topics.subscribe(engine, "engine/calibration/control", MQTTQoS.atMostOnce, engine::onCalibration);
                if (config.faultTrackingEnabled != FeatureEnabled.nothing) {
                    topics.subscribe(engine, faultFeedback, engine::onFault);
                }
            }

            if (config.lightsEnabled != FeatureEnabled.nothing) {
                final String lightsAmbientFeedback = "lights/ambient/feedback";
                final AmbientLightBehavior ambientLight = new AmbientLightBehavior(runtime,
                        topics.publish(lightsAmbientFeedback, false, MQTTQoS.atMostOnce));
                topics.subscribe(ambientLight, allFeedback, MQTTQoS.atMostOnce, ambientLight::onAllFeedback);

                final LightingBehavior lights = new LightingBehavior(runtime, actuatorPowerBInternal, config.lightActuatorPort,
                        topics.publish("lights/override/feedback", false, MQTTQoS.atMostOnce),
                        topics.publish(lightsPowerFeedback, false, MQTTQoS.atMostOnce),
                        topics.publish("lights/calibration/feedback", false, MQTTQoS.atMostOnce));


                topics.subscribe(lights, allFeedback, MQTTQoS.atMostOnce, lights::onAllFeedback);
                topics.subscribe(lights, "lights/override/control", MQTTQoS.atMostOnce, lights::onOverride);
                topics.subscribe(lights, "lights/calibration/control", MQTTQoS.atMostOnce, lights::onCalibration);
                topics.subscribe(lights, lightsAmbientFeedback, lights::onDetected);
            }
        }
        if (config.faultTrackingEnabled == FeatureEnabled.full) {
            final AccelerometerBehavior accelerometerBehavior = new AccelerometerBehavior(runtime, accelerometerInternal);
            topics.registerBehavior(accelerometerBehavior);
        }

        if (config.faultTrackingEnabled != FeatureEnabled.nothing) {
            final FaultTrackingBehavior motionFault = new FaultTrackingBehavior(runtime,
                    topics.publish(faultFeedback, false, MQTTQoS.atMostOnce));
            topics.subscribe(motionFault, allFeedback, MQTTQoS.atMostOnce, motionFault::onAllFeedback);
            topics.subscribe(motionFault, "fault/control", MQTTQoS.atMostOnce, motionFault::onForceFault);
            topics.subscribe(motionFault, accelerometerInternal, motionFault::onAccelerometer);
            topics.subscribe(motionFault, engineState, motionFault::onEngineState);
        }

        if (config.billboardEnabled != FeatureEnabled.nothing) {
            final TextDisplayBehavior billboard = new TextDisplayBehavior(runtime, config.trainDisplayName,
                    topics.publish("billboard/text/feedback", false, MQTTQoS.atMostOnce));
            topics.subscribe(billboard, allFeedback, MQTTQoS.atMostOnce, billboard::onAllFeedback);
            topics.subscribe(billboard, "billboard/text/control", MQTTQoS.atMostOnce, billboard::onText);
            topics.subscribe(billboard, lightsPowerFeedback, billboard::onLightsPower);
        }

        if(config.locationEnabled) {
            final String locationFeedback = "location/feedback";
            final String accuracyFeedback = "location/accuracy/feedback";

            final TrainingBehavior training = new TrainingBehavior(runtime);
            topics.subscribe(training, "location/training/start", MQTTQoS.atLeastOnce, training::onTrainingStart);

            final LocationBehavior location = new LocationBehavior(runtime,
                    topics.publish(locationFeedback, false, MQTTQoS.atMostOnce),
                    topics.publish(accuracyFeedback, false, MQTTQoS.atMostOnce));
            runtime.registerListener(location);
        }

        if (config.appServerEnabled) {
            final String webFeedback = "web/feedback";
            final WebHostBehavior webHost = new WebHostBehavior(runtime, config.resourceRoot, config.resourceDefaultPath,
                    topics.publish(webFeedback, false, MQTTQoS.atMostOnce));
            topics.subscribe(webHost, allFeedback, MQTTQoS.atMostOnce, webHost::onAllFeedback);
        }

        topics.close();
    }
}
