class Button
{
  
  int value;
  int signal_group = 0;
  int associated_signal_group = -1;
  int serial_index = -1;
  int midi_pitch = -1;
  
  Button(int pitch) {
    midi_pitch = pitch;
  }
  
  void send_your_command(float velocity) {
    new Tone(MIDI_CHANNEL,this.midi_pitch,round(127*velocity),TONE_LENGTH,this.associated_signal_group,this.serial_index);
  }
   
}
