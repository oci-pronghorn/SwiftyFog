package com.ociweb;

import com.ociweb.behaviors.*;
import com.ociweb.gl.api.MQTTBridge;
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

        // TODO: calculating maxMessageLength anf maxinFlight given the private channel definitions and arbitrary bridging
        // is too difficult. And we are declaring this in connections where channel message lengths are in behavior
        if (config.mqttEnabled) {
            this.mqttBridge = c.useMQTT(config.mqttBroker, config.mqttPort, false, config.mqttClientName, 20, 15000)
                    .cleanSession(true)
                    .keepAliveSeconds(10);
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

        if (c.isTestHardware()) c.enableTelemetry();

        // TODO: only needed for MQTT connect workaround
        c.setTimerPulseRate(500);
    }

    @Override
    public void declareBehavior(FogRuntime runtime) {
        // Topics
        final String prefix = config.trainName + "/";
        final String actuatorPowerTopic = "actuator/power";

        final String enginePowerTopic = "engine/power";
        final String engineCalibrateTopic = "engine/calibrate";
        final String enginePoweredTopic = "engine/powered";
        final String engineCalibratedTopic = "engine/calibrated";

        final String lightsPoweredTopic = "lights/powered";
        final String lightsOverrideTopic = "lights/override";
        final String lightCalibrateTopic = "lights/calibrate";
        final String ambientLightPublishTopic = "lights/ambient";
        final String lightCalibratedTopic = "lights/calibrated";

        final String accelerometerPublishTopic = "accelerometer";

        final String billboardImageTopic = "billboard/image";
        final String billboardSpecPublishTopic = "billboard/spec";

        // TODO: this is a hack - remove when we have the listener
        final String mqttConnectedTopic = "mqttConnected";
        runtime.registerListener(new MQttConnectedWorkAround(runtime, mqttConnectedTopic));

        // TODO: all inbound have the train name wildcard topic

        // All transmissions should have retain so controlling UIs can always get the latest state
        // Schema defining tramsmissions should have a qos of atLeastOnce

        if (config.appServerEnabled) {
            runtime.addFileServer("").includeAllRoutes(); // TODO: use resource folder
        }

        if (config.engineEnabled || config.lightsEnabled) {
            final ActuatorDriverBehavior actuator = new ActuatorDriverBehavior(runtime);
            runtime.registerListener(actuator)
                    .addSubscription(actuatorPowerTopic, actuator::setPower);
        }

        if (config.engineEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeSubscription(enginePowerTopic, prefix + enginePowerTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeSubscription(engineCalibrateTopic, prefix + engineCalibrateTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(enginePoweredTopic, prefix + enginePoweredTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce).setRetain(true);
                runtime.bridgeTransmission(engineCalibratedTopic, prefix + engineCalibratedTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce).setRetain(true);
            }
            final EngineBehavior engine = new EngineBehavior(runtime, actuatorPowerTopic, config.engineAccuatorPort, enginePoweredTopic, engineCalibratedTopic);
            runtime.registerListener(engine)
                    .addSubscription(mqttConnectedTopic, engine::onMqttConnected)
                    .addSubscription(enginePowerTopic, engine::onPower)
                    .addSubscription(engineCalibrateTopic, engine::onCalibrate);
        }

        if (config.lightsEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeSubscription(lightsOverrideTopic, prefix + lightsOverrideTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeSubscription(lightCalibrateTopic, prefix + lightCalibrateTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(ambientLightPublishTopic, prefix + ambientLightPublishTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce).setRetain(true);
                runtime.bridgeTransmission(lightsPoweredTopic, prefix + lightsPoweredTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce).setRetain(true);
                runtime.bridgeTransmission(lightCalibratedTopic, prefix + lightCalibratedTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce).setRetain(true);
            }
            final AmbientLightBroadcast ambientLight = new AmbientLightBroadcast(runtime, config.lightSensorPort, ambientLightPublishTopic);
            runtime.registerListener(ambientLight);
            final LightingBehavior lights = new LightingBehavior(runtime, actuatorPowerTopic, config.lightAccuatorPort, lightsPoweredTopic, lightCalibratedTopic);
            runtime.registerListener(lights)
                    .addSubscription(mqttConnectedTopic, lights::onMqttConnected)
                    .addSubscription(lightsOverrideTopic, lights::onOverride)
                    .addSubscription(lightCalibrateTopic, lights::onCalibrate)
                    .addSubscription(ambientLightPublishTopic, lights::onDetected);
        }

        if (config.speedometerEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeTransmission(accelerometerPublishTopic, prefix + accelerometerPublishTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce).setRetain(true);
            }
            final AccelerometerBehavior accelerometer = new AccelerometerBehavior(runtime, accelerometerPublishTopic);
            runtime.registerListener(accelerometer);
            //runtime.registerListener(new RailTieSensingBehavior(runtime));
        }

        if (config.billboardEnabled) {
            if (config.mqttEnabled) {
                runtime.bridgeSubscription(billboardImageTopic, prefix + billboardImageTopic, mqttBridge).setQoS(MQTTQOS.atMostOnce);
                runtime.bridgeTransmission(billboardSpecPublishTopic, prefix + billboardSpecPublishTopic, mqttBridge).setQoS(MQTTQOS.atLeastOnce).setRetain(true);
            }
            final BillboardBehavior billboard = new BillboardBehavior(runtime, billboardSpecPublishTopic);
            runtime.registerListener(billboard)
                    .addSubscription(mqttConnectedTopic, billboard::onMqttConnected)
                    .addSubscription(billboardImageTopic, billboard::displayImage);
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
    }
}
