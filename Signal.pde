import processing.serial.*;
import java.util.regex.*;

int[] tempValues = new int[NUMBER_OF_SIGNALS];

class Signal
{
  boolean simulation;
  private Serial myPort = null;
  private String inBuffer = "";
  Pattern input_text_pattern;
  Axis[] axis_dim;
  Button[] button_dim;
  int nr_groups = 2;
  int lines_read, numbers_read;
  boolean last_time_we_extracted_a_number = false;
  float time_of_first_signal_MS = -1.0;
  String read_input_line;
  float time_of_last_line_read_ms;
  
  
  
  Signal(PApplet app, boolean simulate_serial_input) {
    simulation = simulate_serial_input;
    // input_text_pattern = Pattern.compile("\\s*-?([0-9]+,){"+(NUMBER_OF_SIGNALS-1)+"}-?[0-9]+\\s+");
    input_text_pattern = Pattern.compile("\\s*<-?([0-9]+,){"+(1+(NUMBER_OF_SIGNALS+NUMBER_OF_BUTTONS)/2+1-1)+"}-?[0-9]+>\\s*");//(channel number,x,y,z,b1,b2,checksum)
    
    axis_dim = new Axis[NUMBER_OF_SIGNALS];    
    for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
      axis_dim[k] = new Axis(MIDI_SIGNAL_IS_AN_INSTRUMENT[k], SIGNAL_GROUP_OF_AXIS[k]);
    }
    
    button_dim = new Button[NUMBER_OF_BUTTONS];    
    for(int k=0; k<NUMBER_OF_BUTTONS; k++) {
      button_dim[k] = new Button(MIDI_BUTTON_CODES[k]);
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
  
  void shutdown_port() {
    if(!this.simulation) {
      this.myPort.stop();
    }
  }
  
  void clear_buffer() {
    this.inBuffer = "";
  }
  
  boolean group_is_already_playing_a_tone(int s_group) {
    // println("DEBUG: Call to group_is_already_playing_a_tone, s_group = "+s_group+", nr. of tones = "+activeTones.length);
    
    for(int mm=0; mm<activeTones.length; mm++) {
      // println("DEBUG: signal group of this tone = "+activeTones[mm].associated_signal_group);
      if(activeTones[mm].associated_signal_group == s_group) {
        // println("DEBUG: There is a tone for signal group #"+s_group+" tone playing already!");
        return true;
      }
    }
    return false;
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
    int triggering_axis = -1;
    // int signal_group_of_max_velocity = 0;
    boolean played_a_tone = false;
    
    for(int group=0; group<this.nr_groups; group++) {
      // once for each singal group (hand)
      triggering_axis = trigger.detect(group);
      if(triggering_axis > -1) {
        // hit!
        screen.draw_vertical_line(triggering_axis);
        
        if(Phases.Recording) {
          screen.alert("recording shake: axis #"+triggering_axis);
          println("recording shake: axis #"+triggering_axis+", signal group #"+group);
          analyzer.outcomes[OUTCOME_TO_PLAY_DURING_REC_WHEN_GROUP_IS_TRIGGERED[group]].play_your_tone(1.9);
        }
        else { // after recording phase
          int most_likely_outcome;
          if( BAYESIAN_MODE_ENABLED ) {
            most_likely_outcome = analyzer.detect(group);
          } else { // if in old linear mode
            most_likely_outcome = triggering_axis;
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
  
  boolean detect_button_press_and_send_command() {
    for(int j=0; j<NUMBER_OF_BUTTONS; j++) {
      if(input.button_dim[j].value < 1) {
        button_dim[j].send_your_command(0.5);
        screen.alert("button #"+j+" presssed!");
        println("button #"+j+" presssed!");
      }
    }
    return true;  
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
        // remove leading and trailing bracket
        s = s.substring(1, s.length() - 1);
        s_split = s.split(",");

        if(lines_read > NUMBER_OF_LINES_TO_SKIP_ON_INIT) {
          int[] read_numbers = new int[s_split.length];
          for(int t=0; t<s_split.length; t++) { read_numbers[t] = int(s_split[t].trim()); }
          
          // Identify individual controllers based on the first number in the string
          int axis_offset = 0; int button_offset = 0;
          if( read_numbers[0] == 2 && NUMBER_OF_SIGNALS > 3 ) { axis_offset = 3; button_offset = 2; } // <--- slight hack, but works for now
          // Checksum test
          int sum = 0;

          for(int t=0; t<read_numbers.length-1; t++) { sum += read_numbers[t]; }
          if( sum == read_numbers[read_numbers.length-1] ) {
            // Passed checksum test
            for(int t=1; t<read_numbers.length-1; t++) {
              if( t < read_numbers.length-3 ) {  //axis numbers
                this.axis_dim[t-1+axis_offset].value = read_numbers[t];
              } else {                           //button numbers
                this.button_dim[t-4+button_offset].value = read_numbers[t]; 
              }
              this.numbers_read++; 
            }
          } else {
            println("DEBUG: Numbers failed checksum test, ignoring line.");
          }
        }

        // remove characters from inBuffer
        inBuffer = inBuffer.substring(0,m.start(0)) + inBuffer.substring(m.end(0),inBuffer.length());
        inBuffer = inBuffer.trim();
      }
    }
    else { // if simulated signal
      for(int k=0; k<NUMBER_OF_SIGNALS; k++) {
        axis_dim[k].value = round((10*k+lines_read)%height + random(0,10));
        this.numbers_read++;
      }
      for(int k=0; k<NUMBER_OF_BUTTONS; k++) {
        button_dim[k].value = 1;
        if(random(0.0, 1.0) < 0.0015) {
          button_dim[k].value = 0;
        }
      }
      found_a_number = !last_time_we_extracted_a_number;  // HACK
      last_time_we_extracted_a_number = found_a_number;
    }

    if(Phases.Init) {
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
