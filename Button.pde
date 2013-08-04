class Button
{
  
  int value;
  int midi_pitch = -1;
  
  Button(int pitch) {
    midi_pitch = pitch;
  }
  
  void send_your_command(float velocity) {
    new Tone(MIDI_CHANNEL, this.midi_pitch, round(127*velocity), TONE_LENGTH, -1, -1);
  }
  
}
