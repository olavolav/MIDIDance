import processing.serial.*;

int[] tempValues = new int[NUMBER_OF_SIGNALS];

class Signal {
  boolean simulation;
  Serial myPort = null;
  String inBuffer = "";
  Pattern input_text_pattern;
  Axis[] axis_dim;
  int nr_groups = 2;
  int channel_of_max_velocity;
  int lines_read;
  boolean last_time_we_extracted_a_number = false;
  
  Signal(boolean simulate_serial_input) {
    simulation = simulate_serial_input;
    input_text_pattern = Pattern.compile("-?([0-9]+,){"+(NUMBER_OF_SIGNALS-1)+"}-?[0-9]+\\s");
    axis_dim = new Axis[NUMBER_OF_SIGNALS];
    
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k] = new Axis(MIDI_SIGNAL_IS_AN_INSTRUMENT[k],MIDI_PITCH_CODES[j%(MIDI_PITCH_CODES.length)]);

      // assign axis to groups (left and right hand)
      axis_dim[k].signal_group = k/3; // HACK! for 3 axis on each controller
    }
    
    if (!simulation) {
      println(Serial.list());
      // myPort = new Serial(this, Serial.list()[SERIAL_PORT_NUMBER], 9600);    (fails at the moment)
      myPort = null;
      lines_read = 0;
    } else {
      println("Simulating serial input...");
    }
  }
  
  boolean read_from_port() {
    if (!this.simulation) {
      if(this.myPort == null) return false;
      if(myPort.available() > 0) return false;
      this.inBuffer = this.inBuffer+this.myPort.readString();
      lines_read++;
    } else {
      inBuffer = "(simulation)";
      lines_read++;
      if(lines_read%2 == 0) return false;
    }
    return true;
  }
  
  boolean extract_next_number_from_buffer() {
    boolean found_a_number = false;
    if (!this.simulation) {
      String s;
      String[] s_split;
      Matcher m = input_text_pattern.matcher(inBuffer);
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
          axis_dim[t].value = int(s_split[t].trim());
          if(DO_AVERAGE_INPUTS) {
            axis_dim[t].value = (axis_dim[t].value+axis_dim[t].old_value)/2;
          }
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

    // println("DEBUG: Found a number? : "+found_a_number);
    // for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
    //   println("k = "+k+", value = "+axis_dim[k].value);
    // }
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k].update_min_and_max();
    }
    // print("found_a_number: "+found_a_number);
    return found_a_number;
  }
  
  void update_temp_values() {
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k].update_past_value();
    }
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
  
  boolean detect_hit_and_play_tone() {
    boolean played_a_tone = false;
    for(int n=0; n<this.nr_groups; n++) {
      // once for each singal group (hand)
      this.channel_of_max_velocity = -1;
      max_velocity = Float.MIN_VALUE;
      for(j=0; j<NUMBER_OF_SIGNALS; j++) {
        if (axis_dim[j].is_instrument && axis_dim[j].signal_group == n && velocity(j) > max_velocity) {
          max_velocity = velocity(j);
          this.channel_of_max_velocity = j;
        }
      }
      if(max_velocity > xthresh && !hand_is_already_playing_a_tone(this.channel_of_max_velocity)) {
        // hit!
        // fill(line_color(channel_of_max_velocity));
        // textAlign(CENTER, CENTER);
        // text("shake: signal #"+this.channel_of_max_velocity,width/2,height/2);
        screen.alert("shake: signal #"+this.channel_of_max_velocity);
        stroke(line_color(this.channel_of_max_velocity), 200);
        line(screen.rolling+ROLLING_INCREMENT,0,screen.rolling+ROLLING_INCREMENT,height);
        new Tone(MIDI_CHANNEL,input.axis_dim[this.channel_of_max_velocity].midi_pitch,round(127+127*max_velocity),TONE_LENGTH,this.channel_of_max_velocity);
        played_a_tone = true;
      }
      
    }
    return played_a_tone;
  }
  
}
