class Button
{
  String label;
  int value, old_value;
  int midi_pitch = -1;
  int millisecond_time_of_last_button_press = 0;
  
  Button(String l, int pitch) {
    label = l;
    midi_pitch = pitch;
  }
  
  String status_string() {
    String status = this.label+": ";
    
    if(this.is_currently_in_pressed_state()) {
      status += "●"; // "O";
    } else {
      status += "◦"; // "X";
    }
    
    return status;
  }
  
  void send_your_command(float velocity) {
    new Tone(MIDI_CHANNEL, this.midi_pitch, round(127*velocity), TONE_LENGTH, -1, -1);
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
    return (value == 0);
  }
  
}
