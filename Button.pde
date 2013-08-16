class Button
{
  String label;
  int value, old_value;
  // int midi_pitch = -1;
  int[] midi_pitch_list;
  int cycle_index;
  int millisecond_time_of_last_button_press = 0;
  
  Button(String l, int[] pitches) {
    label = l;
    midi_pitch_list = pitches;
    cycle_index = 0;
  }
  
  String status_string() {
    String status = this.label+": ";
    
    if(this.is_currently_in_pressed_state()) {
      status += "●"; // "O";
    } else {
      status += "◦"; // "X";
    }
    
    if(this.is_cycle_button()) {
      status += " step " + (this.cycle_index + 1);
    }
    
    return status;
  }
  
  void send_your_command(float velocity) {
    int code = this.midi_pitch_list[cycle_index];
    new Tone(MIDI_CHANNEL, code, round(127*velocity), TONE_LENGTH, -1, -1);
    cycle_index = (cycle_index + 1) % this.midi_pitch_list.length;
  }
  
  void new_value(int v) {
    old_value = value;
    value = v;
  }
  
  boolean was_pressed_just_now() {
    if((value == 0) && (old_value == 1) && (millis() - millisecond_time_of_last_button_press > 200)) {
      millisecond_time_of_last_button_press = millis();
      return true;
    }
    return false;
  }
  
  boolean is_currently_in_pressed_state() {
    return (this.value == 0);
  }
  
  boolean is_cycle_button() {
    return this.midi_pitch_list.length > 1;
  }
  
}
