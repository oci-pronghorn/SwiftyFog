package com.ociweb.model;

import com.ociweb.gl.api.*;
import com.ociweb.gl.impl.stage.CallableMethod;
import com.ociweb.iot.hardware.HardwareImpl;
import com.ociweb.iot.maker.ListenerFilterIoT;

import java.util.HashMap;
import java.util.Map;

// Accumulates MQTT pubs and subs so maker does not have to reason duplicates across behaviors
// Attempts DRY principle with topic names
// Combines data routed MQTT pub/sub and FogLight pub/sub into one declaration
// Allows a behavior to be registered more than once if that makes maker's code easier to read
// Encapsulates internal/external mapping for mqtt
// MQTT can be disabled (optional null)

public class PubSub {
    private final CharSequence externalScope;
    private final MQTTBridge mqttBridge;
    private final MsgRuntime<HardwareImpl, ListenerFilterIoT> runtime;

    private static class Trans {
        MQTTQoS qos;
        boolean retain;
    }

    private final Map<Behavior, ListenerFilter> registeredListeners = new HashMap<>();
    private final Map<String, MQTTQoS> accumeMQTTSubscriptions = new HashMap<>();
    private final Map<String, Trans> accumeMQTTTransmissions = new HashMap<>();

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
            accumeMQTTTransmissions.compute(topic, (key, oldValue) -> {
                if (oldValue == null || qos.getSpecification() > oldValue.qos.getSpecification() || !oldValue.retain) {
                    Trans tran = new Trans();
                    tran.retain = retain;
                    tran.qos = qos;
                    return tran;
                }
                return oldValue;
            });
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
        ListenerFilter filter = registeredListeners.computeIfAbsent(listener, (k) -> runtime.registerListener(listener.getClass().getSimpleName(), k));
        registeredListeners.put(listener, filter.addSubscription(topic, method));
    }

    public void finish() {
        if (mqttBridge != null) {
            for (Map.Entry<String, MQTTQoS> entry : accumeMQTTSubscriptions.entrySet()) {
                String internalTopic = entry.getKey();
                String externalTopic = externalScope + internalTopic;
                runtime.bridgeSubscription(internalTopic, externalTopic, mqttBridge).setQoS(entry.getValue());
            }
            for (Map.Entry<String, Trans> entry : accumeMQTTTransmissions.entrySet()) {
                String internalTopic = entry.getKey();
                String externalTopic = externalScope + internalTopic;
                MQTTQoS qos = entry.getValue().qos;
                boolean retain = entry.getValue().retain;
                runtime.bridgeTransmission(internalTopic, externalTopic, mqttBridge).setQoS(qos).setRetain(retain);
            }
        }
    }
}
