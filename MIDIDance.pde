import processing.serial.*;
import themidibus.*;

// todo:
// - fix inBuffer display


////////////////////////////////////////////////////////////////////////////////////////////////// init /////////////

// MIDI:
MidiBus myBus;
Tone[] activeTones = new Tone[0];
int MIDI_CHANNEL = 0;
String MIDI_DEVICE_NAME = "IAC-Bus 1"; // or "Java Sound Synthesizer" or "Native Instruments Kore Player Virtual Input"
// String MIDI_DEVICE_NAME = "Java Sound Synthesizer";
int[] MIDI_PITCH_CODES = {41,53,55}; //,41+1,53+1,55+1};
boolean[] MIDI_SIGNAL_IS_AN_INSTRUMENT = {true,true,true,false,true,true};
float TONE_LENGTH = 300.; // in ms

// The serial port:
int SERIAL_PORT_NUMBER = 0;
Serial myPort = null;
String inBuffer = "";
String inStrings[];

// float signals_per_draw_call = 0.;
// int signals_per_this_draw_call = 0;
// the y coordinate where the graphs are updated
int rolling = 0;
int BLENDDOWN_ALPHA = 10;
int ROLLING_INCREMENT = 2;
int NUMBER_OF_SIGNALS = 6;
int[] oldValues = new int[NUMBER_OF_SIGNALS];
int[] tempValues = new int[NUMBER_OF_SIGNALS];
int[] values = new int[NUMBER_OF_SIGNALS];
int[] valuesMinima = new int[NUMBER_OF_SIGNALS];
int[] valuesMaxima = new int[NUMBER_OF_SIGNALS];
boolean DO_SIGNAL_REWIRING = false;
// int[] SIGNAL_REWIRING = {0,0,0,1,1,1};
// int[] SIGNAL_REWIRING = {0,1,0,2,3,2};
int[] SIGNAL_REWIRING = {3,4,5,0,1,2}; // swap controllers!
int i,j;
color[] LINE_COLORS = {#1BA5E0,#B91BE0,#E0561B,#42E01B,#EDE13B,#D4AADC};
Pattern MY_PATTERN = Pattern.compile("-?([0-9]+,){"+(NUMBER_OF_SIGNALS-1)+"}-?[0-9]+\\s");
float INIT_SECONDS = 10.;
float xthresh = 0.3;
float max_velocity;
int channel_of_max_velocity;

boolean DO_AVERAGE_INPUTS = false;


void setup() { //////////////////////////////////////////////////////////////////////////////// setup /////////////
  size(600,400);
  background(0);
  textFont(createFont("LucidaGrande", 18));

  // List all the available serial ports:
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[SERIAL_PORT_NUMBER], 9600);
  
  // List all available Midi devices on STDOUT. This will show each device's index and name.
  MidiBus.list();
  // Create a new MidiBus
  myBus = new MidiBus(this, -1, MIDI_DEVICE_NAME);
  delay(500);
  // play test MIDI sound
  // println("playing test sound!");
  // int pitch = 64;
  // int velocity = 127;
  // new Tone(MIDI_CHANNEL, pitch, velocity, TONE_LENGTH, 0);
  
  for(i=0; i<NUMBER_OF_SIGNALS; i++) {
    oldValues[i] = 0;
    valuesMinima[j] = Integer.MAX_VALUE;
    valuesMaxima[j] = Integer.MIN_VALUE;
  }
    
  // test number extraction from inBuffer
  // println("testing number extraction:"); 
  // String[] testStrings = new String[4];
  // int in;
  // testStrings[0] = "3,2\n";
  // testStrings[1] = "32\n555,5";
  // testStrings[2] = "335,368,305\n-329,367,303\n326,366,305\n-345,0,-303\n330,371,303\n334,366,";
  // testStrings[3] = "335,368,305\n329,367,303\n326,366,305\n345,368,303\n330,371,303\n334,366,";
  // for(j=0; j<4; j++) {
  //   println("test string #"+j+":");
  //   inBuffer = testStrings[j];
  //   while (extractNextNumberFromBuffer()) {
  //     print("-> ");
  //     for(i=0; i<NUMBER_OF_SIGNALS; i++)
  //       print(values[i]+" ");
  //     print("\n");
  //   }
  // }
  // exit();
}

void draw() { //////////////////////////////////////////////////////////////////////////////// draw /////////////
  fadeOutTones();
  update_value_display();
  // signals_per_this_draw_call = 0;
  
  // read values from Arduino
  while (myPort != null && myPort.available() > 0) {
    inBuffer = inBuffer+myPort.readString();
    // print("debug: inBuffer = "+inBuffer+"\n");
    while (extractNextNumberFromBuffer()) {
      // signals_per_this_draw_call++;
            
      // update minima and maxima
      for(j=0; j<NUMBER_OF_SIGNALS; j++) {
        if(values[j] < valuesMinima[j]) valuesMinima[j] = values[j];
        if(values[j] > valuesMaxima[j]) valuesMaxima[j] = values[j];
        // println("debug: min,max of #"+j+" are: "+valuesMinima[j]+","+valuesMaxima[j]);
      }
  
      // display values as graph
      rolling = (rolling+ROLLING_INCREMENT)%width;
      strokeWeight(2);
      for(j=0; j<NUMBER_OF_SIGNALS; j++) {
        stroke(line_color(j), 200);
        line(rolling, round(height*rescale_to_unit(oldValues[j],j)), rolling+ROLLING_INCREMENT,
          round(height*rescale_to_unit(values[j],j)));
      }
      
      // react to input, play sounds etc. after some init time
      if(millis()/1000. > INIT_SECONDS) {
        // send controller changes
        for(j=0; j<NUMBER_OF_SIGNALS; j++) {
          if(!isInstrument(j) && oldValues[j]!=values[j]) {
          	myBus.sendControllerChange(MIDI_CHANNEL, j, round(127*rescale_to_unit(values[j],j))); // Send a controllerChange
          }
        }
        
        // left hand
        channel_of_max_velocity = -1;
        max_velocity = Float.MIN_VALUE;
        for(j=0; j<NUMBER_OF_SIGNALS/2; j++) {
          if(isInstrument(j) && velocity(j) > max_velocity) {
            max_velocity = velocity(j);
            channel_of_max_velocity = j;
          }
        }
        if(max_velocity > xthresh && !hand_is_already_playing_a_tone(channel_of_max_velocity)) {
          // hit!
          // fill(line_color(channel_of_max_velocity));
          // textAlign(CENTER, CENTER);
          // text("shake: signal #"+channel_of_max_velocity,width/2,height/2);
          stroke(line_color(channel_of_max_velocity), 200);
          line(rolling+ROLLING_INCREMENT,0,rolling+ROLLING_INCREMENT,height);
          new Tone(MIDI_CHANNEL,midi_pitch(channel_of_max_velocity),round(127+127*max_velocity),TONE_LENGTH,channel_of_max_velocity);
        }

        // right hand
        channel_of_max_velocity = -1;
        max_velocity = Float.MIN_VALUE;
        for(j=NUMBER_OF_SIGNALS/2; j<NUMBER_OF_SIGNALS; j++) {
          if(isInstrument(j) && velocity(j) > max_velocity) {
            max_velocity = velocity(j);
            channel_of_max_velocity = j;
          }
        }
        if(max_velocity > xthresh && !hand_is_already_playing_a_tone(channel_of_max_velocity)) {
          // hit!
          // fill(line_color(channel_of_max_velocity));
          // textAlign(CENTER, CENTER);
          // text("shake: signal #"+channel_of_max_velocity,width/2,height/2);
          stroke(line_color(channel_of_max_velocity), 200);
          line(rolling+ROLLING_INCREMENT,0,rolling+ROLLING_INCREMENT,height);
          new Tone(MIDI_CHANNEL,midi_pitch(channel_of_max_velocity),round(127+127*max_velocity),TONE_LENGTH,channel_of_max_velocity);
        }


      }
      else {
        textAlign(CENTER, CENTER);
        fill(#FFFFFF);
        text("get ready!",width/2,height/2);
      }
    }
    for(j=0; j<NUMBER_OF_SIGNALS; j++) {
      oldValues[j] = values[j];
    }
  }
  delay(40);
  simple_blenddown(BLENDDOWN_ALPHA);
  // signals_per_draw_call = 0.5*signals_per_draw_call + 0.5*signals_per_this_draw_call;
}

float velocity(int channel) {
  return abs(rescale_to_unit(values[j],j)-rescale_to_unit(oldValues[j],j));
}

color line_color(int j) {
  return LINE_COLORS[j%(LINE_COLORS.length)];
}

int midi_pitch(int j) {
  return MIDI_PITCH_CODES[j%(MIDI_PITCH_CODES.length)];
}

boolean isInstrument(int j) {
  return MIDI_SIGNAL_IS_AN_INSTRUMENT[j%(MIDI_SIGNAL_IS_AN_INSTRUMENT.length)];
}

float rescale_to_unit(int input, int index) {
  // return zero if max and min values make no sense (i.e. are not set yet)
  if ((1.*valuesMaxima[index]-valuesMinima[index]) <= 0) return 0;
  // if not, return so that min and max are top and bottom of window  
  return (1.*input-valuesMinima[index]) / (1.*valuesMaxima[index]-valuesMinima[index]);
}

void simple_blenddown(int alpha) {
  noSmooth();
  noStroke();
  fill(#000000, alpha);
  rect(0, 0, width, height);
  smooth();
}

boolean extractNextNumberFromBuffer() {
  boolean found_a_number = false;
  String s;
  String[] s_split;
  Matcher m = MY_PATTERN.matcher(inBuffer);
  if (m.find()) {
    // println("debug in found a number pattern...");
    found_a_number = true;
    s = m.group(0).trim();
    // print("this one here: "+s);
    s_split = s.split(",");
    
    if(s_split.length != NUMBER_OF_SIGNALS) {
      inBuffer = "";
    }
    
    for(int t=0; t<s_split.length; t++) {
      values[t] = int(s_split[t].trim());
      if(DO_AVERAGE_INPUTS) {
        values[t] = (values[t]+oldValues[t])/2;
      }
    }

    if (DO_SIGNAL_REWIRING) {
      for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
        tempValues[k] = values[k];
        values[k] = 0;
      }
      for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
        if(SIGNAL_REWIRING[k] >= 0)
          values[SIGNAL_REWIRING[k]] += abs(tempValues[k]);
      }
    }

    // remove characters from inBuffer
    inBuffer = inBuffer.substring(0,m.start(0))+inBuffer.substring(m.end(0),inBuffer.length());
  }
  
  return found_a_number;
}

class Tone {
  int channel;
  int pitch;
  int velocity;
  float durationMS;
  float startMS;
  int signal; // from which MIDI channel the tone was triggered
  
  Tone(int c, int p, int v, float d, int s) {
    channel = c;
    pitch = p;
    velocity = v;
    durationMS = d;
    startMS = millis();
    signal = s;
    myBus.sendNoteOn(channel, pitch, velocity);
    // append it to the list of active tones unless there is one with same the parameters c,p
    boolean is_present = false;
    for(int m=0; m<activeTones.length; m++) {
      if(activeTones[m].channel == c && activeTones[m].pitch == p) {
        activeTones[m].velocity = v;
        activeTones[m].durationMS = d;
        activeTones[m].startMS = millis();
        activeTones[m].signal = s;
        is_present = true;
      }
    }
    // println("debug in Tone: adding tone, is_present: "+int(is_present));
    if(!is_present) {
      Tone[] newActiveTones = new Tone[activeTones.length+1];
      for(int m=0; m<activeTones.length; m++) {
        newActiveTones[m] = activeTones[m];
      }
      newActiveTones[activeTones.length] = this;
      activeTones = newActiveTones;
    }
    // println("debug in Tone: new number of active tones: "+activeTones.length);
  }
  
  void kill() {
    myBus.sendNoteOff(this.channel, this.pitch, this.velocity);
  }
}

void fadeOutTones() {
  Tone ton;
  for(int m=0; m<activeTones.length; m++) {
    ton = activeTones[m];
    if(millis()-ton.startMS > ton.durationMS) {
      // remove tone from list and kill it
      // println("debug in fadeOutTones: killing tone #"+m+", "+(activeTones.length-1)+" tones remaining active.");
      // myBus.sendNoteOff(ton.channel, ton.pitch, ton.velocity);
      ton.kill();
      Tone[] newActiveTones = new Tone[activeTones.length-1];
      int m_added = 0;
      for(int mm=0; mm<activeTones.length; mm++) {
        if(ton != activeTones[mm]) {
          newActiveTones[m_added] = activeTones[mm];
          m_added++;
        }
      }
      activeTones = newActiveTones;
    }
  }
}

void update_value_display() {
  String add_for_controller;
  textAlign(LEFT, CENTER);
  for(int j=0; j<NUMBER_OF_SIGNALS; j++) {
    if(isInstrument(j)) add_for_controller = "";
    else add_for_controller = "(ctrl) ";

    fill(#000000);
    text(add_for_controller+j+": "+oldValues[j]+", "+round(100.*rescale_to_unit(oldValues[j],j)),10,20*j+10);
    fill(line_color(j),200);
    text(add_for_controller+j+": "+values[j]+", "+round(100.*rescale_to_unit(values[j],j)),10,20*j+10);
  }
}

void keyPressed()
{
	fill(#FFFFFF);
  textAlign(CENTER, CENTER);
	switch(key)
  {
		case '+':
		  xthresh += 0.02;
		  text("xthresh = "+xthresh, width/2, height/2);
		  break;
		case '-':
		  xthresh -= 0.02;
		  text("xthresh = "+xthresh, width/2, height/2);
		  break;
		case 't':
      text("test tone (general)", width/2, height/2);
      new Tone(MIDI_CHANNEL,60,127,TONE_LENGTH,0);
      break;
		case '0':
      text("test tone for axis #0!", width/2, height/2);
      new Tone(MIDI_CHANNEL,midi_pitch(0),127,TONE_LENGTH,0);
      break;
		case '1':
      text("test tone for axis #1!", width/2, height/2);
      new Tone(MIDI_CHANNEL,midi_pitch(1),127,TONE_LENGTH,1);
      break;
		case '2':
      text("test tone for axis #2!", width/2, height/2);
      new Tone(MIDI_CHANNEL,midi_pitch(2),127,TONE_LENGTH,2);
      break;
		case 'd':
		  println("--- DEBUG INFO ---");
      // println("signals_per_draw_call = "+signals_per_draw_call);
		  println("inBuffer = "+inBuffer);
		  inBuffer = "";
      break;
    case 'h':
      text("help:\n"+
        "+ raise threshold\n"+
        "- lower threshold\n"+
        "t play test tone\n"+
        "h print this help message\n"+
        "(0-9) play saved test tones\n"+
        "d print debug info, then clear inBuffer\n"+
        "ESC quit",
        width/2, height/2);
      break;
	}
}

boolean hand_is_already_playing_a_tone(int channel) {
  boolean found_a_live_tone = false;
  int startchannel = 0;
  if(channel>2) startchannel = 3;
  for(int mm=0; mm<activeTones.length; mm++) {
    if(activeTones[mm].signal >= startchannel && activeTones[mm].signal < startchannel+3) {
      found_a_live_tone = true;
      break;
    }
  }
  return found_a_live_tone;
}