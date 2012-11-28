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
  int lines_read;
  boolean last_time_we_extracted_a_number = false;
  
  Signal(PApplet app, boolean simulate_serial_input) {
    simulation = simulate_serial_input;
    input_text_pattern = Pattern.compile("-?([0-9]+,){"+(NUMBER_OF_SIGNALS-1)+"}-?[0-9]+\\s");
    axis_dim = new Axis[NUMBER_OF_SIGNALS];
    
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k] = new Axis(MIDI_SIGNAL_IS_AN_INSTRUMENT[k],MIDI_PITCH_CODES[k%(MIDI_PITCH_CODES.length)]);

      // assign axis to groups (left and right hand)
      // axis_dim[k].signal_group = k/3; // HACK! for 3 axis on each controller
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
      lines_read = 0;
    } else {
      println("Simulating serial input...");
    }
  }
  
  void clear_buffer() {
    this.inBuffer = "";
  }
  
  boolean group_is_already_playing_a_tone(int channel) {
    boolean found_a_live_tone = false;
    int s_group = this.axis_dim[channel].signal_group;
    // println("DEBUG: Call to group_is_already_playing_a_tone, s_group = "+s_group+", nr. of tones = "+activeTones.length);
    
    for(int mm=0; mm<activeTones.length; mm++) {
      // println("DEBUG: signal group of this tone = "+this.axis_dim[activeTones[mm].signal].signal_group);
      if(this.axis_dim[activeTones[mm].signal].signal_group == s_group) {
        // println("DEBUG: There is a tone already!");
        found_a_live_tone = true;
        break;
      }
    }
    
    return found_a_live_tone;
  }
  
  boolean send_controller_changes() {
    boolean updated_a_controller = false;

    for(j=0; j<NUMBER_OF_SIGNALS; j++) {
      if(!axis_dim[j].is_instrument && axis_dim[j].old_value != axis_dim[j].value) {
      	myBus.sendControllerChange(MIDI_CHANNEL, j, round(127*axis_dim[j].normalized_value())); // Send a controllerChange
      	updated_a_controller = true;
      }
    }
    return updated_a_controller;
  }
  
  boolean detect_hit_and_play_tones() {
    int channel_of_max_velocity = -1;
    boolean played_a_tone = false;
    
    for(int n=0; n<this.nr_groups; n++) {
      // once for each singal group (hand)
      max_velocity = Float.MIN_VALUE;
      for(j=0; j<NUMBER_OF_SIGNALS; j++) {
        if (this.axis_dim[j].is_instrument && this.axis_dim[j].signal_group == n && this.axis_dim[j].velocity() > max_velocity) {
          max_velocity = this.axis_dim[j].velocity();
          channel_of_max_velocity = j;
        }
      }
      if(max_velocity > this.xthresh && !this.group_is_already_playing_a_tone(channel_of_max_velocity)) {
        // hit!
        screen.alert("shake: signal #"+channel_of_max_velocity);
        println("shake: signal #"+channel_of_max_velocity);
        stroke(line_color(channel_of_max_velocity), 200);
        line(screen.rolling+ROLLING_INCREMENT,0,screen.rolling+ROLLING_INCREMENT,height);
        this.axis_dim[channel_of_max_velocity].play_your_tone(max_velocity,channel_of_max_velocity);
        played_a_tone = true;
      }
      
    }
    return played_a_tone;
  }
  
  boolean get_next_data_point() {
    this.update_past_values();
    // read new numbers from buffer or input port
    if(this.extract_next_set_of_numbers_from_buffer()) return true;
    return this.read_from_port();
  }
  
  private boolean read_from_port() {
    if (!this.simulation) {
      if(this.myPort == null) return false;
      if(this.myPort.available() == 0) return false;
      this.inBuffer = this.inBuffer+this.myPort.readString();
      lines_read++;
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
        s_split = s.split(",");

        if(s_split.length != NUMBER_OF_SIGNALS) {
          inBuffer = "";
        }

        for(int t=0; t<s_split.length; t++) {
          axis_dim[t].value = int(s_split[t].trim());
        }

        if (DO_SIGNAL_REWIRING) {
          for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
            tempValues[k] = axis_dim[k].value;
            axis_dim[k].value = 0;
          }
          for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
            if(SIGNAL_REWIRING[k] >= 0)
              axis_dim[SIGNAL_REWIRING[k]].value += abs(tempValues[k]);
          }
        }

        // remove characters from inBuffer
        inBuffer = inBuffer.substring(0,m.start(0))+inBuffer.substring(m.end(0),inBuffer.length());
      }
    }
    else { // if simulated signal
      for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
        axis_dim[k].value = round((10*k+lines_read)%height);
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
    }
    return found_a_number;
  }

  private void update_past_values() {
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k].update_past_value();
    }
  }
  
  private void callback_on_read_new_numbers() {
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k].update_vector_of_past_values_for_hit_recording();
    }
  }

}
