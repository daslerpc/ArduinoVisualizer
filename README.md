# ArduinoVisualizer
A program built in Processing for visualizing analog and digital inputs on an Arduino.

The arduino_data folder contains a sample sketch that outputs three analog signals and a digital one.

The visualizer contains the visualization code itself.  The visualizer will check the data on the serial line looking for the various channels being output by the Arduino.  The data will be graphed in one of three ways:
	Multigraph
	Single graph
	Abstract graph
	
There are three buttons on the lower left that will allow you to switch between these graph modes.  Additionally, each possible channel is listed on the bottom.  Those that were found while scanning the serial port are highlighted and assigned a color to be graphed in.  You can turn off the display of these channels by clicking on the box.

The abstract graph displays a star for every channel.  The inner yellow star shows the minimal value for the channel, the outer red star shows the maximum, and the middle blue star shows the value itself.