import themidibus.*;


////////////////////////////////////////////////////////////////////////////////////////////////// init /////////////

// MIDI:
MidiBus myBus;
Tone[] activeTones = new Tone[0];

// For collecting a history of hits and adapting thresholds:
boolean LEARNING_MODE_ENABLED = true;
Hit[] collectedHits = new Hit[0];
String RECORDED_HITS_OUTPUT_FILE = "test1.txt";

int MIDI_CHANNEL = 0;
// String MIDI_DEVICE_NAME = "IAC-Bus 1"; // or "Java Sound Synthesizer" or "Native Instruments Kore Player Virtual Input"
String MIDI_DEVICE_NAME = "Native Instruments Kore Player Virtual Input";
boolean[] MIDI_SIGNAL_IS_AN_INSTRUMENT = {true,true,true,true,true,true}; // 1 for each outcome
float TONE_LENGTH = 300.; // in ms

// The serial port:
boolean SIMULATE_SERIAL_INPUT = false;
int NUMBER_OF_LINES_TO_SKIP_ON_INIT = 10;
int SERIAL_PORT_NUMBER = 0;
int SERIAL_PORT_BAUD_RATE = 9600;
Signal input;
int[] SIGNAL_GROUP_OF_AXIS = {0, 0, 0, 1, 1, 1};
int LENGTH_OF_PAST_VALUES = 30;

// The Bayesian movement analyzer:
String[] OUTCOMES_LABEL = {"null-right", "null-left", "right-out", "left-down"};
int[] MIDI_PITCH_CODES = {-1,-1,41,53,55,41+1,53+1,55+1}; // one for each outcome
int[] SIGNAL_GROUP_OF_OUTCOME = {0, 1, 0, 0}; //, 0, 0, 1, 1, 1};
int[] NULL_OUTCOME_FOR_SIGNAL_GROUP = {0, 1};
MovementAnalyzer analyzer;
int triggered_analyzer_event;
boolean currently_in_recording_phase = false;
int LENGTH_OF_PAST_VALUES_FOR_BAYESIAN_ANALYSIS = 20;
int MAX_NUMBER_OF_EVENTS_FOR_LEARNING = 100;
int[] OUTCOME_TO_PLAY_DURING_REC_WHEN_GROUP_IS_TRIGGERED = {0, 1};

int BLENDDOWN_ALPHA = 20;
int ROLLING_INCREMENT = 1;
int NUMBER_OF_SIGNALS = 6;
boolean DO_SIGNAL_REWIRING = false;
int[] SIGNAL_REWIRING = {3,4,5,0,1,2}; // swap controllers!
int i,j;
color[] LINE_COLORS = {#1BA5E0,#B91BE0,#E0561B,#42E01B,#EDE13B,#D4AADC};
float INIT_SECONDS = 15.;
float max_velocity;

Display screen;
String[] AXIS_LABELS = {"1x", "1y", "1z", "2x", "2y", "2z"};
int last_displayed_second_init, current_second_init;

void setup() { //////////////////////////////////////////////////////////////////////////////// setup /////////////
  
  if(test_setup() == false) {
    println("-> Error: Invalid setup parameters!");
    exit();
  }
  
  size(600,400);
  screen = new Display(0);

  // Init serial ports
  input = new Signal(this,SIMULATE_SERIAL_INPUT);
  
  analyzer = new MovementAnalyzer();
  if(LEARNING_MODE_ENABLED) {
    currently_in_recording_phase = true;
  }
    
  // List all available Midi devices on STDOUT. This will show each device's index and name.
  MidiBus.list();
  myBus = new MidiBus(this, -1, MIDI_DEVICE_NAME);
  delay(500);
  last_displayed_second_init = ceil(INIT_SECONDS - millis()/1000.0);
}

void draw() { //////////////////////////////////////////////////////////////////////////////// draw /////////////
  fadeOutTones();
  screen.update_value_display();
  
  // read values from Arduino
  while (input.get_next_data_point()) {
    if(currently_in_init_phase()) {
      screen.alert("get ready!");
      current_second_init = ceil(INIT_SECONDS - millis()/1000.0);
      if( current_second_init < last_displayed_second_init ) {
        if( current_second_init < 10 ) { screen.huge_alert(str(current_second_init)); }
        last_displayed_second_init = current_second_init;
      }
    } else { // during active phase
      input.send_controller_changes();
      input.detect_hit_and_play_tones();
    }
    screen.update_graphs();
  }
  delay(40);
  screen.simple_blenddown(BLENDDOWN_ALPHA);
}

void keyPressed() {
  if(key>=int('0') && key <=int('9')) {
    int ch = int(key) - int('0');
    if(ch < OUTCOMES_LABEL.length) {
      if(LEARNING_MODE_ENABLED) {
        if(collectedHits.length > 0) {
          collectedHits[collectedHits.length-1].target_outcome = ch;
          screen.alert("LEARN: Set target of last hit to #"+ch+" ("+analyzer.outcomes[ch].label+")");
        }
      } else { // no learning mode
        screen.alert("Playing test tone of channel #"+ch);
        // input.axis_dim[ch].play_your_tone(127,ch);
        analyzer.outcomes[ch].play_your_tone(127); //,ch);
      }
    }
  } else {
  	switch(key) {
  	  case '+':
  		  input.xthresh += 0.02;
  		  screen.alert("xthresh = "+input.xthresh);
  		  break;
  		case '-':
  		  input.xthresh -= 0.02;
  		  screen.alert("xthresh = "+input.xthresh);
  		  break;
  		case 'd':
  		  println("--- DEBUG INFO ---");
  		  println("inBuffer = "+input.inBuffer);
  		  println("number of lines read = "+input.lines_read);
  		  println("rate of signal input per axis = "+input.rate_of_signal_per_axis_Hz()+" Hz");
  		  println("rolling = "+screen.rolling);
  		  println("number of recoded hits = "+collectedHits.length);
  		  println("rec. hits by target outcome: "+analyzer.status_of_recorded_hits_per_outcome());
        break;
      case 'r':
        input.clear_buffer();
        println("Reset input buffer.");
        break;
      case 'w':
        screen.alert("Writing recorded hits to file now.");
        String[] for_saving = new String[collectedHits.length];
        for(int n=0; n<collectedHits.length; n++) {
          for_saving[n] = collectedHits[n].status_information();
        }
        saveStrings(RECORDED_HITS_OUTPUT_FILE,for_saving);
        break;
      case 'z':
        if( LEARNING_MODE_ENABLED ) {
          if( analyzer.learn_based_on_recorded_hits() ) {
            currently_in_recording_phase = false;
            screen.alert("Bayesian models completed.");
          } else {
            screen.alert("Bayesian models could not be completed.");
          }
        }
        break;
      case 'h':
        String help_message = "help:\n"+
          "+ raise threshold\n"+
          "- lower threshold\n"+
          "h print this help message\n"+
          "r reset input buffer\n"+
          "w write recorded hits to disk\n"+
          "d print debug info\n"+
          "ESC quit\n";
        if(LEARNING_MODE_ENABLED) {
          help_message += "(0-9) assign target channel to last hit\nz end learning mode and define Bayesian models (!)";
        } else {
          help_message += "(0-9) play test tone of outcome";
        }        
        screen.alert(help_message);
        break;
  	}
	}
}

boolean currently_in_init_phase() {
  return (millis()/1000.0 < INIT_SECONDS);
}

boolean test_setup() {
  boolean all_fine = true;
  
  if(SIGNAL_GROUP_OF_AXIS.length != NUMBER_OF_SIGNALS) { println("test_setup: error #1!"); all_fine = false; }
  if(SIGNAL_GROUP_OF_OUTCOME.length != OUTCOMES_LABEL.length) { println("test_setup: error #2!"); all_fine = false; }
  if(LENGTH_OF_PAST_VALUES_FOR_BAYESIAN_ANALYSIS > LENGTH_OF_PAST_VALUES) { println("test_setup: error #3!"); all_fine = false; }
  if(DO_SIGNAL_REWIRING) { println("test_setup: error #4!"); all_fine = false; } // not implemented yet
  if(OUTCOME_TO_PLAY_DURING_REC_WHEN_GROUP_IS_TRIGGERED.length != NULL_OUTCOME_FOR_SIGNAL_GROUP.length) { println("test_setup: error #5!"); all_fine = false; }
  
  for(int oo=0; oo<OUTCOMES_LABEL.length; oo++) {
    if(SIGNAL_GROUP_OF_OUTCOME[oo] < 0) { println("test_setup: error #6!"); all_fine = false; }
  }
  
  return all_fine;
}
