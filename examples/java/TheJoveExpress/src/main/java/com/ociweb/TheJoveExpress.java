package com.ociweb;

import com.ociweb.behaviors.*;
import com.ociweb.behaviors.internal.AccelerometerBehavior;
import com.ociweb.behaviors.internal.PWMActuatorDriverBehavior;
import com.ociweb.behaviors.internal.SharedActuatorDriverBehavior;
import com.ociweb.behaviors.location.LocationBehavior;
import com.ociweb.behaviors.location.TrainingBehavior;
import com.ociweb.gl.api.MQTTBridge;
import com.ociweb.gl.api.MQTTQoS;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
import com.ociweb.iot.maker.Baud;
import com.ociweb.iot.maker.FogApp;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.pronghorn.iot.i2c.I2CJFFIStage;
import com.ociweb.pronghorn.stage.scheduling.GraphManager;

import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_128x64;

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

        if (config.mqttEnabled) {
            this.mqttBridge = hardware.useMQTT(config.mqttBrokerHost, config.mqttPort, config.mqttClientName, 40, 8000)
                    .cleanSession(true)
                    .keepAliveSeconds(10);
        }
        WebHostBehavior.enable(hardware, config.appServerEnabled, config.appServerPort);

        if (config.lightsEnabled) {
            hardware.setTimerPulseRate(1000); // needed for startup flash
            if (!hardware.isTestHardware() || config.simulateLightSensor) {
                hardware.connect(SimpleAnalogTwig.LightSensor, config.lightSensorPort, config.lightDetectFreq);
            }
        }
        if (config.soundEnabled) hardware.useSerial(Baud.B_____9600);

        if (config.billboardEnabled) hardware.connect(OLED_128x64);/*c.connect(OLED_96x96);*/
 //       if (config.faultDetectionEnabled) hardware.connect(SixAxisAccelerometerTwig.SixAxisAccelerometer.readAccel, config.accelerometerReadFreq);
        if (config.soundEnabled) ; //c.connect(serial mp3 player);

        if (config.telemetryEnabled) {
            hardware.enableTelemetry(config.telemetryHost, config.telemetryPort);
        }
        
        if (config.sharedAcutatorEnabled) {
            SharedActuatorDriverBehavior.connectHardaware(hardware,config.lightsEnabled || config.engineEnabled)    ;
        } else {
            PWMActuatorDriverBehavior.connectHardware(hardware,
                    config.engineEnabled ? config.pwmEnginePowerPort : null,
                    config.engineEnabled ? config.pwmEngineDirectionPort : null,
                    config.lightsEnabled ? config.ledPort : null);
        }
    }

    public void declareBehavior(FogRuntime runtime) {
        // BUG: Only the last behavior that publishes "lifecycle/feedback" actually gets out to MQTT!
        // BUG: LightingBehavior is not receiving "lights/ambient/feedback" (probably related)

        TopicJunctionBox topics = new TopicJunctionBox(config.trainName, runtime, config.mqttEnabled ? mqttBridge : null);

        if (config.lifecycleEnabled) {
            final String lifeCycleFeedback = "lifecycle/feedback";
            final String internalMqttConnect = "MQTT/Connection";
            final String shutdownControl = "lifecycle/control/shutdown";
            topics.lastWill(lifeCycleFeedback, true, MQTTQoS.atLeastOnce, blobWriter -> blobWriter.writeBoolean(false)); // TODO remove immutable check
            topics.connectionFeedbackTopic(internalMqttConnect);
            LifeCycleBehavior lifeCycle = new LifeCycleBehavior(runtime,
                    topics.publish(lifeCycleFeedback, true, MQTTQoS.atLeastOnce));
            topics.subscribe(lifeCycle, internalMqttConnect, MQTTQoS.atLeastOnce, lifeCycle::onMQTTConnect);
            topics.subscribe(lifeCycle, shutdownControl, MQTTQoS.atMostOnce, lifeCycle::onShutdown);
        }

        final String allFeedback = "feedback";
        final String accelerometerInternal = "accelerometer/internal";
        final String engineState = "engine/state/feedback";
        final String faultFeedback = "fault/feedback";
        final String lightsPowerFeedback = "lights/power/feedback";

        if (config.engineEnabled || config.lightsEnabled) {
            final String actuatorPowerAInternal = "actuator/power/a/internal";
            final String actuatorPowerBInternal = "actuator/power/b/internal";

            /////////
            /////////
            
            if (config.sharedAcutatorEnabled) {
            	final SharedActuatorDriverBehavior actuator = new SharedActuatorDriverBehavior(runtime);
            	topics.subscribe(actuator, actuatorPowerAInternal, actuator::setPower);
            	topics.subscribe(actuator, actuatorPowerBInternal, actuator::setPower);
            }
        /*    else {
                final PWMActuatorDriverBehavior actuator = new PWMActuatorDriverBehavior(runtime, config.engineActuatorPort);
                topics.subscribe(actuator, actuatorPowerAInternal, actuator::setPower);
                topics.subscribe(actuator, actuatorPowerBInternal, actuator::setPower);
            }*/

            if (config.engineEnabled) {
                
            	if (config.sharedAcutatorEnabled) { 
	            	final EngineBehavior engine = new EngineBehavior(runtime, config.defaultEngineCalibration, actuatorPowerAInternal, config.engineActuatorPort,
	                        topics.publish("engine/power/feedback", false, MQTTQoS.atMostOnce),
	                        topics.publish("engine/calibration/feedback", false, MQTTQoS.atMostOnce),
	                        topics.publish("engine/state/feedback", false, MQTTQoS.atMostOnce));
	                            	
	            	topics.subscribe(engine, allFeedback, MQTTQoS.atMostOnce, engine::onAllFeedback);
	                topics.subscribe(engine, "engine/power/control", MQTTQoS.atMostOnce, engine::onPower);
	                topics.subscribe(engine, "engine/calibration/control", MQTTQoS.atMostOnce, engine::onCalibration);
	                if (config.faultDetectionEnabled) {
	                	topics.subscribe(engine, faultFeedback, engine::onFault);
	                }
            	} else {
					//simple PwM control          		
	            	final EngineBehaviorPWM engine = new EngineBehaviorPWM(runtime, config.pwmEnginePowerPort, config.pwmEngineDirectionPort,
	                        topics.publish("engine/power/feedback", false, MQTTQoS.atMostOnce),
	                        topics.publish("engine/calibration/feedback", false, MQTTQoS.atMostOnce),
	                        topics.publish("engine/state/feedback", false, MQTTQoS.atMostOnce));
	                            	
	            	topics.subscribe(engine, allFeedback, MQTTQoS.atMostOnce, engine::onAllFeedback);
	                topics.subscribe(engine, "engine/power/control", MQTTQoS.atMostOnce, engine::onPower);
	                topics.subscribe(engine, "engine/calibration/control", MQTTQoS.atMostOnce, engine::onCalibration);
	                if (config.faultDetectionEnabled) {
	                	topics.subscribe(engine, faultFeedback, engine::onFault);
	                }
            		
            	}
                
            }

            if (config.lightsEnabled) {
                
            	if (config.sharedAcutatorEnabled) { 
	            	final String lightsAmbientFeedback = "lights/ambient/feedback";
	                final AmbientLightBehavior ambientLight = new AmbientLightBehavior(runtime, config.lightSensorPort,
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
            	} else {

            		
	            	final String lightsAmbientFeedback = "lights/ambient/feedback";
	                final AmbientLightBehavior ambientLight = new AmbientLightBehavior(runtime, config.lightSensorPort,
	                        topics.publish(lightsAmbientFeedback, false, MQTTQoS.atMostOnce));
	                topics.subscribe(ambientLight, allFeedback, MQTTQoS.atMostOnce, ambientLight::onAllFeedback);
	
					final LightingBehaviorPWM lights = new LightingBehaviorPWM(runtime, config.ledPort, 
	                		topics.publish("lights/override/feedback", false, MQTTQoS.atMostOnce),
	                        topics.publish(lightsPowerFeedback, false, MQTTQoS.atMostOnce),
	                        topics.publish("lights/calibration/feedback", false, MQTTQoS.atMostOnce));
	                
	                
	                topics.subscribe(lights, allFeedback, MQTTQoS.atMostOnce, lights::onAllFeedback);
	                topics.subscribe(lights, "lights/override/control", MQTTQoS.atMostOnce, lights::onOverride);
	                topics.subscribe(lights, "lights/calibration/control", MQTTQoS.atMostOnce, lights::onCalibration);
	                topics.subscribe(lights, lightsAmbientFeedback, lights::onDetected);
            		
            		
            	}
                
                
            }
        }
        if (config.faultDetectionEnabled) {
            final AccelerometerBehavior accelerometerBehavior = new AccelerometerBehavior(runtime, accelerometerInternal);
            topics.registerBehavior(accelerometerBehavior);
        }

        if (config.faultDetectionEnabled) {
            final MotionFaultBehavior motionFault = new MotionFaultBehavior(runtime,
                    topics.publish(faultFeedback, false, MQTTQoS.atMostOnce));
            topics.subscribe(motionFault, allFeedback, MQTTQoS.atMostOnce, motionFault::onAllFeedback);
            topics.subscribe(motionFault, "fault/control", MQTTQoS.atMostOnce, motionFault::onForceFault);
            topics.subscribe(motionFault, accelerometerInternal, motionFault::onAccelerometer);
            topics.subscribe(motionFault, engineState, motionFault::onEngineState);
        }

        if (config.billboardEnabled) {
            final TextDisplay billboard = new TextDisplay(runtime, config.trainDisplayName,
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
