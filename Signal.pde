import processing.serial.*;

int[] tempValues = new int[NUMBER_OF_SIGNALS];

class Signal {
  boolean simulation;
  private Serial myPort = null;
  private String inBuffer = "";
  Pattern input_text_pattern;
  Axis[] axis_dim;
  int nr_groups = 2;
  float xthresh = 0.3;
  int lines_read, numbers_read;
  boolean last_time_we_extracted_a_number = false;
  float time_of_first_signal_MS = -1.0;
  String read_input_line;
  float time_of_last_line_read_ms;
  
  Signal(PApplet app, boolean simulate_serial_input) {
    simulation = simulate_serial_input;
    input_text_pattern = Pattern.compile("\\s*-?([0-9]+,){"+(NUMBER_OF_SIGNALS-1)+"}-?[0-9]+\\s+");
    axis_dim = new Axis[NUMBER_OF_SIGNALS];
    
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k] = new Axis(MIDI_SIGNAL_IS_AN_INSTRUMENT[k], SIGNAL_GROUP_OF_AXIS[k]);
    }
    
    if (!simulation) {
      println(Serial.list());
      println("Setting up connection to serial port: "+Serial.list()[SERIAL_PORT_NUMBER]);
      myPort = new Serial(app, Serial.list()[SERIAL_PORT_NUMBER], SERIAL_PORT_BAUD_RATE);
      if(myPort == null) {
        println("Error! Null serial port."); exit();
      } else {
        println("-> done.");
      }
    } else {
      println("Simulating serial input...");
    }
    lines_read = 0;
    numbers_read = 0;
  }
  
  void clear_buffer() {
    this.inBuffer = "";
  }
  
  boolean group_is_already_playing_a_tone(int s_group) {
    boolean found_a_live_tone = false;
    // println("DEBUG: Call to group_is_already_playing_a_tone, s_group = "+s_group+", nr. of tones = "+activeTones.length);
    
    for(int mm=0; mm<activeTones.length; mm++) {
      // println("DEBUG: signal group of this tone = "+activeTones[mm].associated_signal_group);
      if(activeTones[mm].associated_signal_group == s_group) {
        // println("DEBUG: There is a tone for that signal group tone playing already!");
        found_a_live_tone = true;
        break;
      }
    }
    return found_a_live_tone;
  }
  
  boolean send_controller_changes() {
    boolean updated_a_controller = false;

    for(j=0; j<NUMBER_OF_SIGNALS; j++) {
      if( !axis_dim[j].is_instrument && abs(axis_dim[j].normalized_old_value()-axis_dim[j].value) > 0.01 ) {
      	myBus.sendControllerChange(MIDI_CHANNEL, j, round(127*axis_dim[j].normalized_value())); // Send a controllerChange
      	updated_a_controller = true;
      }
    }
    return updated_a_controller;
  }
  
  boolean detect_hit_and_play_tones() {
    int axis_of_max_velocity = -1;
    int signal_group_of_max_velocity = 0;
    boolean played_a_tone = false;
    
    for(int n=0; n<this.nr_groups; n++) {
      // once for each singal group (hand)
      max_velocity = Float.MIN_VALUE;
      for(j=0; j<NUMBER_OF_SIGNALS; j++) {
        if (this.axis_dim[j].is_instrument && this.axis_dim[j].signal_group == n && this.axis_dim[j].velocity() > max_velocity) {
          max_velocity = this.axis_dim[j].velocity();
          axis_of_max_velocity = j;
        }
      }
      
      if( axis_of_max_velocity >= 0 ) {
        signal_group_of_max_velocity = input.axis_dim[axis_of_max_velocity].signal_group;
      }
      if(max_velocity > this.xthresh && !this.group_is_already_playing_a_tone(signal_group_of_max_velocity)) {
        // hit!
        screen.draw_vertical_line( axis_of_max_velocity );

        if( currently_in_recording_phase ) {
          screen.alert("recording shake: axis #"+axis_of_max_velocity);
          println("recording shake: axis #"+axis_of_max_velocity+", signal group #"+signal_group_of_max_velocity);
          analyzer.outcomes[OUTCOME_TO_PLAY_DURING_REC_WHEN_GROUP_IS_TRIGGERED[signal_group_of_max_velocity]].play_your_tone(1.9);
        }
        else { // after recording phase
          int most_likely_outcome = -1;
          if( BAYESIAN_MODE_ENABLED ) {
            most_likely_outcome = analyzer.detect( signal_group_of_max_velocity );
          } else { // if in old linear mode
            most_likely_outcome = axis_of_max_velocity;
          }
          if( most_likely_outcome >= 0 ) {
            analyzer.outcomes[most_likely_outcome].play_your_tone(1.9); //max_velocity);
          }
          screen.alert("shake: outcome #"+most_likely_outcome+" ("+analyzer.outcomes[most_likely_outcome].label+")");
          println("shake: outcome is #"+most_likely_outcome+" ("+analyzer.outcomes[most_likely_outcome].label+")");
        }
        
        played_a_tone = true;
      }
      
    }
    return played_a_tone;
  }
  
  boolean get_next_data_point() {
    // read new numbers from buffer or input port
    if(this.extract_next_set_of_numbers_from_buffer()) return true;
    return this.read_from_port();
  }
  
  private boolean read_from_port() {
    if (!this.simulation) {
      if(this.myPort == null) return false;
      if(this.myPort.available() == 0) return false;
      this.read_input_line = this.myPort.readString();
      this.inBuffer = this.inBuffer+this.read_input_line;
      lines_read++;
      if( millis() - this.time_of_first_signal_MS > 500.0 ) { screen.alert("signal lost!"); }
      if( this.read_input_line.trim() != "" ) { this.time_of_first_signal_MS = millis(); }
    } else {
      this.inBuffer = "(simulation)";
      this.lines_read++;
      if(this.lines_read%2 == 0) return false;
    }
    return true;
  }
  
  private boolean extract_next_set_of_numbers_from_buffer() {
    boolean found_a_number = false;
    if (!this.simulation) {
      String s;
      String[] s_split;
      Matcher m = input_text_pattern.matcher(inBuffer);
      if (m.find()) {
        found_a_number = true;
        s = m.group(0).trim();
        s_split = s.trim().split(",");

        if(s_split.length != NUMBER_OF_SIGNALS) {
          println("DEBUG: Invalid pattern, clearing input buffer!");
          inBuffer = "";
        }

        if(lines_read > NUMBER_OF_LINES_TO_SKIP_ON_INIT) {
          for(int t=0; t<s_split.length; t++) {
            this.axis_dim[t].value = int(s_split[t].trim());
            this.numbers_read++;
            
            // DEBUG
            if(this.axis_dim[t].value > 900) {
              print("DEBUG: large number! inBuffer = "+this.inBuffer);
            }
          }
        }

        // remove characters from inBuffer
        inBuffer = inBuffer.substring(0,m.start(0)) + inBuffer.substring(m.end(0),inBuffer.length());
      }
    }
    else { // if simulated signal
      for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
        axis_dim[k].value = round((10*k+lines_read)%height);
        this.numbers_read++;
      }
      found_a_number = !last_time_we_extracted_a_number;  // HACK
      last_time_we_extracted_a_number = found_a_number;
    }

    if(currently_in_init_phase()) {
      for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
        axis_dim[k].update_min_and_max();
      }
    }
    
    if(found_a_number || this.simulation) {
      this.callback_on_read_new_numbers();
      
      if(this.time_of_first_signal_MS < 0.0) {
        this.time_of_first_signal_MS = millis();
      }
    }
    return found_a_number;
  }

  private void callback_on_read_new_numbers() {
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k].update_vector_of_past_values();
    }
  }
  
  float rate_of_signal_per_axis_Hz() {
    if( this.time_of_first_signal_MS < 0.0 || this.lines_read == 0 )
      { return 0.0; }
    return (this.numbers_read/this.axis_dim.length) / ((millis() - this.time_of_first_signal_MS)/1000.0);
  }

}
