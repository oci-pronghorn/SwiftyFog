package com.ociweb.model;

import com.ociweb.gl.api.*;
import com.ociweb.gl.impl.stage.CallableMethod;
import com.ociweb.iot.hardware.HardwareImpl;
import com.ociweb.iot.maker.ListenerFilterIoT;

import java.util.HashMap;
import java.util.Map;

// TODO: finish and move to GL
public class PubSub {
    private CharSequence externalScope;
    private MQTTBridge mqttBridge;
    private MsgRuntime<HardwareImpl, ListenerFilterIoT> runtime;

    private Map<Behavior, ListenerFilter> registeredListeners = new HashMap<>();
    private Map<String, MQTTQoS> accumeMQTTSubscriptions = new HashMap<>();

    public PubSub(String externalScope, MsgRuntime<HardwareImpl, ListenerFilterIoT> runtime, MQTTBridge mqttBridge) {
        this.externalScope = externalScope + "/";
        this.mqttBridge = mqttBridge;
        this.runtime = runtime;
    }

    public void lastWill(String topic, boolean retain, MQTTQoS qos, Writable payload) {
        if (mqttBridge != null) {
            mqttBridge.lastWill(externalScope + topic, retain, qos, payload);
        }
    }

    public void connectionFeedbackTopic(String connectFeedbackTopic) {
        if (mqttBridge != null) {
            mqttBridge.connectionFeedbackTopic(connectFeedbackTopic);
        }
    }

    public void registerBehavior(Behavior behavior) {
        ListenerFilter filter = registeredListeners.computeIfAbsent(behavior, (k) -> runtime.registerListener(k));
        registeredListeners.put(behavior, filter);
    }

    public String publish(String topic, boolean retain, MQTTQoS qos) {
        if (mqttBridge != null) {
            runtime.bridgeTransmission(topic, externalScope + topic, mqttBridge).setQoS(qos).setRetain(retain);
        }
        return topic;
    }

    public void subscribe(PubSubMethodListener listener, String topic, MQTTQoS qos, CallableMethod method) {
        this.subscribe(listener, topic, method);
        accumeMQTTSubscriptions.compute(topic, (key, oldValue) -> {
            if (oldValue == null || qos.getSpecification() > oldValue.getSpecification()) {
                return qos;
            }
            return oldValue;
        });
    }

    public void subscribe(PubSubMethodListener listener, String topic, CallableMethod method) {
        ListenerFilter filter = registeredListeners.computeIfAbsent(listener, (k) -> runtime.registerListener(k));
        registeredListeners.put(listener, filter.addSubscription(topic, method));
    }

    public void finish() {
        if (mqttBridge != null) {
            for (Map.Entry<String, MQTTQoS> entry : accumeMQTTSubscriptions.entrySet()) {
                runtime.bridgeSubscription(entry.getKey(), externalScope + entry.getKey(), mqttBridge).setQoS(entry.getValue());
            }
        }
    }
}
