package com.ociweb;

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

public class TopicJunctionBox implements AutoCloseable {
    private final CharSequence externalScope;
    private final MQTTBridge mqttBridge;
    private final MsgRuntime<HardwareImpl, ListenerFilterIoT> runtime;

    private static class MQTTTransmission {
        MQTTQoS qos;
        boolean retain;
    }

    private final Map<Behavior, ListenerFilter> registeredListeners = new HashMap<>();
    private final Map<String, MQTTQoS> accumeMQTTSubscriptions = new HashMap<>();
    private final Map<String, MQTTTransmission> accumeMQTTTransmissions = new HashMap<>();

    // To disable MQTT, pass in null for mqttBridge
    // externalScope can be null as well
    public TopicJunctionBox(String externalScope, MsgRuntime<HardwareImpl, ListenerFilterIoT> runtime, MQTTBridge mqttBridge) {
        this.externalScope = externalScope != null && !externalScope.isEmpty() ? externalScope + "/" : "";
        this.mqttBridge = mqttBridge;
        this.runtime = runtime;
    }

    // Setup MQTT last will
    public void lastWill(String topic, boolean retain, MQTTQoS qos, Writable payload) {
        if (mqttBridge != null) {
            mqttBridge.lastWill(externalScope + topic, retain, qos, payload);
        }
    }

    // Get notified of connection state of MQTT connections
    public void connectionFeedbackTopic(String connectFeedbackTopic) {
        if (mqttBridge != null) {
            mqttBridge.connectionFeedbackTopic(connectFeedbackTopic);
        }
    }

    // Declare that a topic goes out to MQTT (if bridge and QOS are not null).
    // Returns the supplied topic for convenience.
    public String publish(String topic, boolean retain, MQTTQoS qos) {
        if (mqttBridge != null && qos != null) {
            accumeMQTTTransmissions.compute(topic, (key, oldValue) -> {
                if (oldValue == null || qos.getSpecification() > oldValue.qos.getSpecification() || !oldValue.retain) {
                    MQTTTransmission transmission = new MQTTTransmission();
                    transmission.retain = retain;
                    transmission.qos = qos;
                    return transmission;
                }
                return oldValue;
            });
        }
        return topic;
    }

    // Has the listener subscribe to the topic.
    // If qos is not null, bind to the MQTT topic as well
    public void subscribe(PubSubMethodListener listener, String topic, MQTTQoS qos, CallableMethod method) {
        this.subscribe(listener, topic, method);
        if (qos != null) {
            accumeMQTTSubscriptions.compute(topic, (key, oldValue) -> {
                if (oldValue == null || qos.getSpecification() > oldValue.getSpecification()) {
                    return qos;
                }
                return oldValue;
            });
        }
    }

    // Has the listener subscribe to the topic.
    public void subscribe(PubSubMethodListener listener, String topic, CallableMethod method) {
        ListenerFilter filter = registerBehavior(listener);
        registeredListeners.put(listener, filter.addSubscription(topic, method));
    }

	public ListenerFilter registerBehavior(PubSubMethodListener listener) {
		return registeredListeners.computeIfAbsent(listener, (k) -> runtime.registerListener(listener.getClass().getSimpleName(), k));
	}

    // Call to finalize and closeup the Junction Box
    @Override
    public void close() {
        if (mqttBridge != null) {
            for (Map.Entry<String, MQTTQoS> entry : accumeMQTTSubscriptions.entrySet()) {
                String internalTopic = entry.getKey();
                String externalTopic = externalScope + internalTopic;
                runtime.bridgeSubscription(internalTopic, externalTopic, mqttBridge).setQoS(entry.getValue());
            }
            for (Map.Entry<String, MQTTTransmission> entry : accumeMQTTTransmissions.entrySet()) {
                String internalTopic = entry.getKey();
                String externalTopic = externalScope + internalTopic;
                MQTTQoS qos = entry.getValue().qos;
                boolean retain = entry.getValue().retain;
                runtime.bridgeTransmission(internalTopic, externalTopic, mqttBridge).setQoS(qos).setRetain(retain);
            }
        }
    }
}
