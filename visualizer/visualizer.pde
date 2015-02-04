/*
 * This project was inspired by Oscilloscope, a project that is part of Accrochages
 * See http://accrochages.drone.ws
 * 
 * (c) 2008 Sofian Audry (info@sofianaudry.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import processing.serial.*;
import java.util.*;

Serial port;  // Create object from Serial class
int val;      // Data received from the serial port
LinkedList<Integer> values;
int readByte;
Map<Integer, LinkedList<Integer>> datastream;
ArrayList<Integer> key_values;
int key_value;
int last_value;
int strip_height;
int toolbar_height = 50;

LinkedList<Integer> tempValues;
static int[] ColorValues;
int chart_width;
int chart_height;
int label_padding;
int history_length;

int mode = 0;
int rect0X, rect0Y;
int rect1X, rect1Y;
int rect2X, rect2Y;

color rectColor;
color rectHighlight;

boolean rect0Over = false;
boolean rect1Over = false;
boolean rect2Over = false;

int button_width = 50;
int button_height = (toolbar_height - 8)/3;

Set<Integer> display_channels = new TreeSet();

void setup() 
{
  createColors(); 
  size(640, 480);
  if (frame != null) {
    frame.setResizable(true);
  }

  label_padding = 20;
  chart_width = width - label_padding;
  chart_height = height - toolbar_height;
  history_length = 1400;

  // Open the port that the board is connected to and use the same speed (9600 bps)
  port = new Serial(this, Serial.list()[9], 9600);
  
  key_values = new ArrayList<Integer>();
  datastream = new LinkedHashMap<Integer, LinkedList<Integer>>();

  getChannelsFromStream();

  smooth();
}

int getY(int index, int type, int val, boolean multi) {
  int value = (int)val*strip_height;

  if ( !multi )
    value = (int)val*chart_height;

  if ( type == 0xa )
    value /= 1023.0f;
  else 
    value *= 0.75;

  //value += 10;//datastream.size() + 2;

  if (multi)
    value += strip_height*index + index;

  return value;
}


void draw()
{
  chart_width = width - label_padding;
  chart_height = height-toolbar_height - 10;
  strip_height = chart_height/display_channels.size()-2;

  background(0);

  updateValues();

  drawUI();

  int key_index = 0;
  int display_index = 0;
  
  for ( Integer key_value : key_values ) {
    if ( display_channels.contains(key_value)) {
      last_value = -1;
      values = datastream.get(key_value);

      switch(mode) {
      case 0:
        drawMultigraph(key_index, key_value, display_index);
        break;
      case 1:
        drawSinglegraph(key_index, key_value, display_index);
        break;
      case 2:
        drawArtsy(display_index, key_value);
        break;
      }
      display_index++;
    }
    key_index++;
  }
}

void drawMultigraph(int key_index, Integer key_value, int display_index) {
  writeLabels();

  stroke(ColorValues[key_index]);
  int x = history_length + label_padding;
  for (Integer value : values) 
  {
    if (last_value != -1 && x < width) 
    {
      line(x+label_padding+1, chart_height - getY(display_index, key_value>>4, last_value, true), 
      x+label_padding, chart_height - getY(display_index, key_value>>4, value, true));
    }
    x--;
    last_value = value;
  }
}

void drawSinglegraph(int key_index, Integer key_value, int display_index) {
  drawAxisLabels();
  
  stroke(ColorValues[key_index]);
  int x = history_length + label_padding;
  for (Integer value : values) 
  {
    if (last_value != -1 && x < width) 
    {
      line(x+label_padding+1, chart_height - getY(display_index, key_value>>4, last_value, false), 
      x+label_padding, chart_height - getY(display_index, key_value>>4, value, false));
    }
    x--;
    last_value = value;
  }
}

void drawArtsy(int display_index, Integer key_value) {
  int hor_spacing = width/((display_channels.size()+1)/2+1);
  int ver_spacing = chart_height/2;
  int x = hor_spacing*(1 + (display_index/2));
  int y = chart_height/4 + ver_spacing*(display_index%2);
  
  if ( display_channels.size() == 1)
    y = chart_height/2;

  int points;
  int max_value;
  if ( key_value >> 4 == 0xa) {
    points = 8;
    max_value = 1023;
  } else {
    points = 3;
    max_value = 1;
  }

  // float max_radius = min(height/4 - 10, hor_spacing);
  float max_radius = min(ver_spacing, hor_spacing)/2 - 5;
  float base_radius = max_radius/4;
  float point_radius = map(values.getLast(), 0, max_value, base_radius, max_radius);

  fill(0xFFFF5858);
  pushMatrix();
  translate(x, y);
  rotate(frameCount / -100.0);
  star(0, 0, 2*base_radius, max_radius, 2*points);  
  popMatrix();

  fill(0xFF43E1E1);
  pushMatrix();
  translate(x, y);
  rotate(frameCount / -100.0);
  star(0, 0, base_radius, point_radius, points);  
  popMatrix();

  fill(0XFFC5FD57);
  pushMatrix();
  translate(x, y);
  rotate(frameCount / -100.0);
  star(0, 0, base_radius, base_radius, points);  
  popMatrix();


  fill(0xFF000000);
  text(Integer.toHexString(key_value), x-7, y+3);
}

void star(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle/2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a+halfAngle) * radius1;
    sy = y + sin(a+halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

void writeLabels() {
  int index = display_channels.size()-1;
  int y;

  fill(255);

  for ( Integer key_value : display_channels) {
    stroke(0x44888888);
    text(Integer.toHexString(key_value), 10, strip_height*(index + 0.5));  
    y = strip_height*index +  + 2*display_channels.size();
    line(0, y, width, y);
    index--;
  }
  y = display_channels.size() * strip_height + 2*display_channels.size();
  line(0, y, width, y);
}

void drawAxisLabels() {
  fill(255);
  stroke(0x44888888);
  
  int line_sep = chart_height/10;
  int y;
  int space = 2;
  
  for( int x=0; x<=10; x++) {
    y = chart_height - x*line_sep;
    line(width-chart_width, y, width, y);
    switch(x) {
      case 0:
        space = 12;
        break;
      case 10:
        space = 0;
        break;
      default:
        space = 4;
    } 
    text(x*100, space, y+5);  
  }
}

void drawUI() {
  stroke(255);
  fill(rectColor);

  int buttonX = 5;

  rect0X = buttonX;
  rect0Y = height - toolbar_height;
  if ( overRect(rect0X, rect0Y, button_width, button_height) )
    fill(rectHighlight);
  else
    fill(rectColor);
  rect(rect0X, rect0Y, button_width, button_height);
  stroke(0);
  line( rect0X + button_width/2 - 10, rect0Y + button_height/2-3, 
  rect0X + button_width/2 + 10, rect0Y + button_height/2-3);
  line( rect0X + button_width/2 - 10, rect0Y + button_height/2, 
  rect0X + button_width/2 + 10, rect0Y + button_height/2);
  line( rect0X + button_width/2 - 10, rect0Y + button_height/2+3, 
  rect0X + button_width/2 + 10, rect0Y + button_height/2+3);

  stroke(255);
  rect1X = buttonX;
  rect1Y = height - toolbar_height + button_height + 2;
  if ( overRect(rect1X, rect1Y, button_width, button_height) )
    fill(rectHighlight);
  else
    fill(rectColor);
  rect(rect1X, rect1Y, button_width, button_height);
  stroke(0);
  line( rect1X + button_width/2 - 10, rect1Y + button_height/2, 
  rect1X + button_width/2 + 10, rect1Y + button_height/2);

  stroke(255);
  rect2X = buttonX;
  rect2Y = height - toolbar_height + 2*(button_height + 2);
  if ( overRect(rect2X, rect2Y, button_width, button_height) )
    fill(rectHighlight);
  else
    fill(rectColor);
  rect(rect2X, rect2Y, button_width, button_height);
  fill(0);
  star(rect2X + button_width/2, rect2Y + button_height/2, button_height/3, button_height/2, 6);

  drawToggles();
}

void drawToggles() {
  int index = 0;

  for ( int x = 0; x < 6; x++ ) {
    stroke(255);
    fill(128);
    if ( key_values.contains(x+0xa0) ) {
      if ( display_channels.contains(x+0xa0) ) {
        fill(ColorValues[index]);
      }
      index++;
      rect(x*45 + button_width + 15, chart_height + 40, 10, 10);
      fill(255);
    }
    text(Integer.toHexString(x + 0xa0), x*45 + button_width + 30, chart_height + 50);
  }

  for ( int x = 0; x < 13; x++ ) {
    stroke(255);
    fill(128);
    if ( key_values.contains(x+0xd0) ) {
      if ( display_channels.contains(x+0xd0) ) {
        fill(ColorValues[index]);
      }
      index++;
      rect(x*45 + button_width + 15, chart_height + 15, 10, 10);
      fill(255);
    }
    text(Integer.toHexString(x + 0xd0), x*45 + button_width + 30, chart_height + 25);
  }
}

boolean overRect(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width && 
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void mousePressed() {
  if ( overRect(rect0X, rect0Y, button_width, button_height) ) {
    mode = 0;
    return;
  } else if ( overRect(rect1X, rect1Y, button_width, button_height) ) {
    mode = 1;
    return;
  } else if ( overRect(rect2X, rect2Y, button_width, button_height) ) {
    mode = 2;
    return;
  }

  for ( int x = 0; x < 6; x++ ) {
    if ( key_values.contains(x+0xa0) &&
      overRect(x*45 + button_width + 15, chart_height + 45, 10, 10)) {
      if ( display_channels.size() > 1 && display_channels.contains(x+0xa0) )
        display_channels.remove(x+0xa0);
      else if( !display_channels.contains(x+0xa0))
        display_channels.add(x+0xa0);
      return;
    }
  }

  for ( int x = 0; x < 13; x++ ) {
    if ( key_values.contains(x+0xd0) &&
      overRect(x*45 + button_width + 15, chart_height + 20, 10, 10)) {
      if ( display_channels.size() > 1 && display_channels.contains(x+0xd0) )
        display_channels.remove(x+0xd0);
      else if( !display_channels.contains(x+0xd0))
        display_channels.add(x+0xd0);
      return;
    }
  }
  return;
}

void updateValues() {
  while (port.available () >= 3) {
    key_value = port.read();

    if ( key_values.contains(key_value) ) {
      val = (port.read() << 8) | (port.read());

      values = datastream.get(key_value);

      values.add(val);
      values.removeFirst();

      datastream.put( key_value, values );
    }
  }
}

void getChannelsFromStream() {
  int read;
  int iterations = 100;
  print("Checking serial port for data channels.");
  while (datastream.size () == 0) {
    iterations--;
    if (iterations % 10 == 0)
      print(".");
    while (port.available () >= 3) {
      if (port.read() == 0xff) {
        read = port.read();
        if ((read >= 0xa0 && read <= 0xa5) || (read >= 0xd0 && read <= 0xdd)) {
          tempValues = new LinkedList<Integer>();
          for (int i=0; i<history_length; i++)
            tempValues.add(0);
          datastream.put(read, tempValues);
          display_channels.add(read);
        }
      }
    }
    if ( iterations == 0 ) {
      println("\nNo channels found in data stream.");
      break;
    }
  }

  key_values.addAll(datastream.keySet());
  Collections.sort(key_values);

  println("\nChannels found: " + key_values);
}

void createColors() {
  ColorValues = new int[] { 
    0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFF00, 0xFFFF00FF, 
    0xFF00FFFF, 0xFFFFFFFF, 0xFF800000, 0xFF008000, 0xFF000080, 
    0xFF808000, 0xFF800080, 0xFF008080, 0xFF808080, 0xFFC00000, 
    0xFF00C000, 0xFF0000C0, 0xFFC0C000, 0xFFC000C0, 0xFF00C0C0
  };

  rectColor = color(180);
  rectHighlight = color(100);
}

