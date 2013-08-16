class Button
{
  
  int value, old_value;
  int midi_pitch = -1;
  int millisecond_time_of_last_button_press = 0;
  
  Button(int pitch) {
    midi_pitch = pitch;
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
  
}
