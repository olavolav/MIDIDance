import themidibus.*;


////////////////////////////////////////////////////////////////////////////////////////////////// init /////////////

// MIDI:
MidiBus myBus;
Tone[] activeTones = new Tone[0];
int MIDI_CHANNEL = 0;
// String MIDI_DEVICE_NAME = "IAC-Bus 1"; // or "Java Sound Synthesizer" or "Native Instruments Kore Player Virtual Input"
String MIDI_DEVICE_NAME = "Java Sound Synthesizer";
int[] MIDI_PITCH_CODES = {41,53,55,41+1,53+1,55+1};
boolean[] MIDI_SIGNAL_IS_AN_INSTRUMENT = {true,true,true,true,true,true};
float TONE_LENGTH = 300.; // in ms

// The serial port:
boolean SIMULATE_SERIAL_INPUT = false;
int SERIAL_PORT_NUMBER = 0;
String inStrings[];
Signal input;

int BLENDDOWN_ALPHA = 20;
int ROLLING_INCREMENT = 2;
int NUMBER_OF_SIGNALS = 6;
boolean DO_SIGNAL_REWIRING = false;
// int[] SIGNAL_REWIRING = {0,0,0,1,1,1};
// int[] SIGNAL_REWIRING = {0,1,0,2,3,2};
int[] SIGNAL_REWIRING = {3,4,5,0,1,2}; // swap controllers!
int i,j;
color[] LINE_COLORS = {#1BA5E0,#B91BE0,#E0561B,#42E01B,#EDE13B,#D4AADC};
float INIT_SECONDS = 6.;
float max_velocity;

boolean DO_AVERAGE_INPUTS = false;
Display screen;


void setup() { //////////////////////////////////////////////////////////////////////////////// setup /////////////
  size(600,400);
  screen = new Display(0);

  // Init serial ports
  input = new Signal(this,SIMULATE_SERIAL_INPUT);
    
  // List all available Midi devices on STDOUT. This will show each device's index and name.
  MidiBus.list();
  myBus = new MidiBus(this, -1, MIDI_DEVICE_NAME);
  delay(500);
  // play test MIDI sound
  // println("playing test sound!");
  // int pitch = 64;
  // int velocity = 127;
  // new Tone(MIDI_CHANNEL, pitch, velocity, TONE_LENGTH, 0);
      
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
  //   while (extract_next_number_from_buffer()) {
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
  screen.update_value_display();
  
  // read values from Arduino
  while (input.read_from_port()) {
    while (input.extract_next_number_from_buffer()) {
      // react to input, play sounds etc. after some init time
      if(millis()/1000. > INIT_SECONDS) {
        input.send_controller_changes();
        input.detect_hit_and_play_tone();
      } else { // during init phase
        screen.alert("get ready!");
      }
      screen.update_graphs();
    }
    input.update_temp_values();
  }
  delay(40);
  screen.simple_blenddown(BLENDDOWN_ALPHA);
}

void keyPressed() {
	switch(key) {
		case '+':
		  input.xthresh += 0.02;
		  screen.alert("xthresh = "+input.xthresh);
		  break;
		case '-':
		  input.xthresh -= 0.02;
		  screen.alert("xthresh = "+input.xthresh);
		  break;
		case 't':
      screen.alert("test tone (general)");
      new Tone(MIDI_CHANNEL,60,127,TONE_LENGTH,0);
      break;
		case '0':
      screen.alert("test tone for axis #0!");
      new Tone(MIDI_CHANNEL,input.axis_dim[0].midi_pitch,127,TONE_LENGTH,0);
      break;
		case '1':
    screen.alert("test tone for axis #1!");
      new Tone(MIDI_CHANNEL,input.axis_dim[1].midi_pitch,127,TONE_LENGTH,1);
      break;
		case '2':
    screen.alert("test tone for axis #2!");
      new Tone(MIDI_CHANNEL,input.axis_dim[2].midi_pitch,127,TONE_LENGTH,2);
      break;
		case 'd':
		  println("--- DEBUG INFO ---");
		  println("inBuffer = "+input.inBuffer);
		  input.inBuffer = "";
		  println("number of lines read = "+input.lines_read);
		  println("rolling = "+screen.rolling);
      break;
    case 'h':
      screen.alert("help:\n"+
        "+ raise threshold\n"+
        "- lower threshold\n"+
        "t play test tone\n"+
        "h print this help message\n"+
        "(0-9) play saved test tones\n"+
        "d print debug info, then clear inBuffer\n"+
        "ESC quit");
      break;
	}
}
