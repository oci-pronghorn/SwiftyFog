#  Verification

Is Alive Indicator:
- Uses sticky published topic and last-will to signal train is connected to broker
- Long press should send a shutdown command to the Train application and train's last-will invoked
- Doubletap rerequests all feedback

Billboard Text:
- "No Connection" is connections are not being made
- "Connecting..." during connection process
- "No Train" if connected to broker but no "Alive" topic received
- Otherwise editable and changes display text on train

Connection Metrics:
- Connections made : Grouped Attemptes : Current Group's Iteration

Connection Indicator:
- Plugged in if connected to broker
- Not plugged in if not connected to broker

Connection Button:
- Red - stop making connections
- Green - make connections

Power Gauge:
- If not making connections - reacts to Power Slider and Calibration Slider, otherwise feedbackloop
- On "Train Alive" immediately sets power , calibration, and indicator to that of the train

Power Slider:
- Sends power signal. Auto updates only on train alive signaled or view loaded.

Amp Calibration Slider:
- Sends amp calibration. Auto updates only on train alive signaled or view loaded.

* Train will power moter per power slider. If power is below calibrated engine will not turn on. Indicator shows engine state.

Light Gauge:
- If not making connections - reacts to Power Slider and Calibration Slider, otherwise feedbackloop
- On "Train Alive" immediately sets ambient light, calibration, and indicator to that of the train

Light Override:
- Sends light override. Auto updates only on train alive signaled or view loaded.

Light Calibration:
- Sends light calibration. Auto updates only on train alive signaled or view loaded.

* Train will keep lights off if override is off, keep lights on if override is on. If auto and ambient light is above calibration then lights are turned on, otherwise off. Indicator always shows if lights are on or off. On train startup lights flash a couple times.

Error Button:
- Sends a forced fault (toggles) to train. Engine turns off when true. iOS display appears to be cracked.
