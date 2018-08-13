package com.ociweb;

/**
 * Allow for a feature to have different run modes
 * dependong on configuration and debugging
 */
public enum FeatureEnabled {
    full,
    noHardware,
    simuatedHardware,
    nothing
}
