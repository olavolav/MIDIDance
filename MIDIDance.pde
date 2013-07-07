import themidibus.*;


/////////////////////////////////////////////////////////////////// init /////////////

// For collecting a history of hits and adapting thresholds:
Hit[] collectedHits = new Hit[0];
// the MIDI bus
MidiBus myBus;
Tone[] activeTones = new Tone[0];
// The serial port
Signal input;
// The display:
Display screen;
int last_displayed_second_init, current_second_init;
// The general analyzer paramters:
MovementAnalyzer analyzer;
MovementTrigger trigger;
int triggered_analyzer_event;
int optimal_bayesian_vector_length = 1;

int i,j;


void setup() { /////////////////////////////////////////////////////////////////// setup /////////////
  
  if(test_setup() == false) {
    println("-> Error: Invalid setup parameters! (see test_setup() in MIDIDance.pde for details)");
    exit();
  }
  
  if( BAYESIAN_MODE_ENABLED ) {
    println("Hit detector mode: Bayesian");
    Phases.Recording = true;
  }
  else { println("Hit detector mode: Max. velocity"); }
  
  size(600,400);
  screen = new Display(0);

  // Init serial ports
  input = new Signal(this,SIMULATE_SERIAL_INPUT);
  
  trigger = new MovementTrigger(TRIGGER_TYPE);
  
  analyzer = new MovementAnalyzer();
    
  // List all available Midi devices on STDOUT. This will show each device's index and name.
  MidiBus.list();
  myBus = new MidiBus(this, -1, MIDI_DEVICE_NAME);
  delay(500);
  last_displayed_second_init = ceil(INIT_SECONDS - millis()/1000.0);
}

void draw() { /////////////////////////////////////////////////////////////////// draw /////////////
  
  fadeOutTones();
  screen.update_value_display();
  
  // read values from Arduino
  while (input.get_next_data_point()) {
    if(Phases.Init) {
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
  
  update_phases();
}

void keyPressed() {
  if(key>=int('0') && key <=int('9')) {
    int ch = int(key) - int('0');
    if(ch < OUTCOMES_LABEL.length) {
      if( BAYESIAN_MODE_ENABLED ) {
        if(collectedHits.length > 0) {
          collectedHits[collectedHits.length-1].target_outcome = ch;
          screen.alert("LEARN: Set target of last hit to #"+ch+" ("+analyzer.outcomes[ch].label+")");
        }
      } else { // no Bayesian mode
        screen.alert("Playing test tone of axis #"+ch);
        analyzer.outcomes[ch].play_your_tone(127); //,ch);
      }
    }
  } else {
    switch(key) {
      case '+':
        trigger.xthreshold += 0.02;
        screen.alert("xthreshold = "+trigger.xthreshold);
        break;
      case '-':
        trigger.xthreshold -= 0.02;
        screen.alert("xthreshold = "+trigger.xthreshold);
        break;
      case 'd':
        println("--- DEBUG INFO ---");
        println("Phases: Init = "+Phases.Init+", Recording = "+Phases.Recording);
        println("Trigger type: "+trigger.explain_type());
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
        save_hits_information_to_file(RECORDED_HITS_OUTPUT_FILE);
        screen.alert("Wrote recorded hits to file.");
        break;
      case 'l':
        if( load_hits_information_from_file(RECORDED_HITS_INPUT_FILE) ) {
          screen.alert("Loaded recorded hits from file.");
        } else {
          screen.alert("Error: Failed to load hits from file.");
        }
        break;
      case 'z':
        if( BAYESIAN_MODE_ENABLED ) {
          if( analyzer.learn_based_on_recorded_hits() ) {
            Phases.Recording = false;
            screen.alert("Bayesian models computed. Projected accuracy = "+analyzer.detect_accuracy_of_all_prerecorded_hits_and_determine_optimal_length());
          } else {
            screen.alert("Bayesian models could not be completed.");
          }
        }
        break;
      case 't':
        TRIGGER_TYPE = trigger.cycle_type();
        screen.alert("switched trigger type: "+trigger.explain_type());
        break;
      case 'h':
        String help_message = "help:\n" +
          "+ raise threshold\n" +
          "- lower threshold\n" +
          "h print this help message\n" +
          "r reset input buffer\n" +
          "d print debug info\n" +
          "t cycle trigger methods\n" +
          "ESC quit\n";
        if( BAYESIAN_MODE_ENABLED ) {
          help_message += "(0-9) assign target channel to last hit\n" +
            "w write recorded hits to disk\n" +
            "l load recorded hits from disk\n" +
            "z end learning mode and define Bayesian models (!)";
        } else {
          help_message += "(0-9) play test tone of axis";
        }        
        screen.alert(help_message);
        break;
    }
  }
}

boolean test_setup() {
  boolean all_fine = true;
  
  if(SIGNAL_GROUP_OF_AXIS.length != NUMBER_OF_SIGNALS) { println("test_setup: error #1!"); all_fine = false; }
  if(SIGNAL_GROUP_OF_OUTCOME.length != OUTCOMES_LABEL.length) { println("test_setup: error #2!"); all_fine = false; }
  if(OUTCOME_TO_PLAY_DURING_REC_WHEN_GROUP_IS_TRIGGERED.length != NULL_OUTCOME_FOR_SIGNAL_GROUP.length) { println("test_setup: error #4!"); all_fine = false; }

  if( !BAYESIAN_MODE_ENABLED && NUMBER_OF_SIGNALS != OUTCOMES_LABEL.length ) { println("test_setup: error #5!"); all_fine = false; }
  
  for(int oo=0; oo<OUTCOMES_LABEL.length; oo++) {
    if(SIGNAL_GROUP_OF_OUTCOME[oo] < 0) { println("test_setup: error #6!"); all_fine = false; }
  }
  
  if(BAYESIAN_MODE_ENABLED) {
    if( SKIP_OUTCOME_WHEN_EVALUATING_BAYESIAN_DETECTOR.length != OUTCOMES_LABEL.length ) {
      println("test_setup: error #7!"); all_fine = false;
    }
  }
  
  return all_fine;
}

void save_hits_information_to_file(String file_name) {
  String[] for_saving = new String[ 3 + analyzer.outcomes.length + 1 + collectedHits.length ];
  int line_count = 0;
  // 1st step: save set-up and set of possible outcomes
  for_saving[line_count++] = str( NUMBER_OF_SIGNALS );
  for_saving[line_count++] = str( LENGTH_OF_PAST_VALUES );
  for_saving[line_count++] = str( analyzer.outcomes.length );
  for(int n=0; n<analyzer.outcomes.length; n++) {
    for_saving[line_count++] = analyzer.outcomes[n].status_information();
  }
  // 2nd step: save recorded hits 
  for_saving[line_count++] = str(collectedHits.length);
  for(int n=0; n<collectedHits.length; n++) {
    for_saving[line_count++] = collectedHits[n].status_information();
  }
  // write to file
  saveStrings(file_name,for_saving);
}

boolean load_hits_information_from_file(String file_name) {
  String[] for_loading = loadStrings(file_name);
  int line_count = 0;
  int putative_number_of_axis = int( for_loading[line_count++] );
  if( putative_number_of_axis != NUMBER_OF_SIGNALS ) {
    println("Error while loading hits: number of axis ("+putative_number_of_axis+") does not match current set-up!");
    return false;
  }

  int putative_length_of_past_vector = int( for_loading[line_count++] );
  if( putative_length_of_past_vector != LENGTH_OF_PAST_VALUES ) {
    println("Error while loading hits: length of past values ("+putative_length_of_past_vector+") does not match current set-up!");
    return false;
  }

  int putative_number_of_outcomes = int( for_loading[line_count++] );
  if( putative_number_of_outcomes != analyzer.outcomes.length ) {
    println("Error while loading hits: number of outcomes ("+putative_number_of_outcomes+") does not match current set-up!");
    return false;
  }

  for(int n=0; n<putative_number_of_outcomes; n++) {
    println("outcome #"+n+" in file was: "+for_loading[line_count++]);
  }
  int putative_number_of_hits = int( for_loading[line_count++] );
  if( for_loading.length != 3 + analyzer.outcomes.length + 1 + putative_number_of_hits ) {
    println("Error while loading hits: File format unknown!");
    return false;
  }

  collectedHits = new Hit[0];
  for(int n=0; n<putative_number_of_hits; n++) {
    String[] hit_detail = for_loading[line_count++].split(",");
    int element = 1; // skipping the time stamp
    int actual_oo = int(hit_detail[element++].trim());
    int target_oo = int(hit_detail[element++].trim());
    println("hit #"+n+" in file was for target outcome #"+target_oo);
    
    Hit new_hit = new Hit(actual_oo,target_oo);
    for(int m=0; m<NUMBER_OF_SIGNALS; m++) {
      for(int n2=0; n2<LENGTH_OF_PAST_VALUES; n2++) {
        new_hit.value_history[m][n2] = float(hit_detail[element++].trim());
      }
    }
  }
  return true;
}
