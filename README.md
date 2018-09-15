# SwiftyFog

## Examples
The iOS/WatchKit example is written to work with the FogLight Java application, also in the examples directory.
The Mac example demonstrates similar concepts for the desktop. 
The AR example demonstrates integration of ARKit and FogLight/SwiftyFog.

## Instructions
To build the Java train application
mvn install
scp target/TheJoveExpress.jar pi@thejoveexpress.local:/home/pi/FogLight
/home/pi/FogLight/openjdk8u144-b01-aarch32-compact1/bin/java -ea -Xmx400m -jar /home/pi/FogLight/TheJoveExpress.jar -w false &> /home/pi/FogLight/log.txt

## Author
dsjove, dsjove@gmail.com
tobischw, schweigert@objectcomputing.com (MacOS integration/AR demo)
