#  Train Control UI Overview

## Train Discovery
Given a broker read from settings both the iOS app and the Watch will auto attach to the first living train if it does not have one.
The iOS app has a train selector popover.

## Train Connection Indicator
The circular icon presents a flat line if train is not connected to the broker or a heartbeat like line otherwise.
A long-press on the indicator sends a shutdown request to the train application. The flat line should appear on train's last will.
A double-tap will send a feedback request where the train will retransmit all states
On transition from flatline to heartbeat the same feadback request is made and controls, not just indicators are updated.
Apple watch has the indicator with gestures.
Apple watch will display train name on initial feedback

## Billboard Text 
The billboard text will be disabled and gold when train is flatlined. Current connection status is displayed in text
* "No Connection" is connections are not being made
* "Connecting..." during connection process
* "No Train" if connected to broker but no "Alive" topic received
If the train is connected the the billboard edit field controls the text on the Train's billboard display.
No watch functionality

## Connection Metrics
This flip labels count down the number of connection attempts to the broker.
| Connections made | Grouped Attempts | Current Group's Iteration |
It is reset whenever connection attempts are manually restarted
Not presented on watch.

## Connection Indicator
If the application has connected to the broker the icon shows a plug plugged-in, otherwise unplugged. It has a pulsating glow on pings.
On watch the Train Indicator shows the disconnected state if not connected to broker. No ping indication.

## Manual Connect Switch
This toggle button toggles betwwen connection desired and make no connection. If no connection is desired, some of the controls will update indicators, bypassing the severed feedback loop. This is for testing. 
Watch always assumes desired connection. Button not present.

## Power Gauge
The analog power gauge presents three peices of information.
* Percent of max power given to the motor (-100 to 100)
* The minimal power threshold where no actual power is sent to the motor
* Backward, Idle, and Forward Indicator
Watch presents power as text and indicator

## Power Slider
The scrub style slider allows the user to start the slide from any tap position and provides haptic feedback on boundary hit. When connections are desired this control does not adjust the guage.
Watch uses the hardware crown

## Calibrate Amps Slider
This standard slider adjusts the minimum amps for the motor.  When connections are desired this control does not adjust the guage.
Not on watch

## Light Gauge
The analog power gauge presents three peices of information.
* Current sensed ambient light (0 to 256)
* The ambient light threshold to auto turn lights on or off
* Lights on/off indicator
Watch presents indicator

## Light Override
This standard segmented control selects between lights On, Off, or Auto.  When connections are desired this control does not adjust the guage.
Implemented as a single button that sequences through options on the watch.

## Light Calibration
This standard slider adjusts the minimum ambient amps to turn lights on in auto mode. When connections are desired this control does not adjust the guage.
Not on watch

## WebView
If the train broadcasts that web page is hosted, the web view is made visible with the appropriate page loaded.
The watch does not have this yet.

## Error
Sends a toggled forced faultto train. Motor turns off when true. iOS display appears to be cracked, plays a sound, and provides haptic feedback.
None of this is implemented on watch yet.
