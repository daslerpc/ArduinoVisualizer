int ledPin = 9;    // LED connected to digital pin 9
int buttonPin = 7;

void writeOscilloscope(int index, int value) {
  Serial.write( 0xff );
  Serial.write( index );                // send init byte
  Serial.write( (value >> 8) & 0xff ); // send first part
  Serial.write( value & 0xff );        // send second part
}

void setup()  {
  // nothing happens in setup
  Serial.begin(9600);
  analogWrite(ledPin, 255);
  pinMode(buttonPin, INPUT);
}
 
void loop()  {
  //read in from Analog0 (which is connected to the potentiometer)
  int sensorValue = analogRead(0);
 
  //remember that our analogWrite has a min value of 0 and a max value of 255,
  //so we should map our input range to our output range
  int analogOut = map(sensorValue, 0, 1023, 0, 255);
  analogWrite(ledPin, analogOut);
 
  //print out the data!
  //String printOut = "sensorValue=" + String(sensorValue) + ", analogOut=" + String(analogOut);
  
  writeOscilloscope(0xa0, sensorValue);
  
  sensorValue = analogRead(1);
  writeOscilloscope(0xa1, sensorValue);
  
  int button = digitalRead(buttonPin);
  writeOscilloscope(0xd7, button);  
  
  sensorValue = analogRead(2);
  writeOscilloscope(0xa2, sensorValue);  

}
