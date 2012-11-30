int LENGTH_OF_PAST_VALUES = 30;

class Axis {
  int value;
  int old_value;
  int value_min, value_max;
  int signal_group = 0;
  boolean is_instrument = true;
  int midi_pitch = -1;
  float[] last_values_buffer;

  Axis(boolean instr, int pitch) {
    value = 0;
    old_value = 0;
    value_min = Integer.MAX_VALUE;
    value_max = Integer.MIN_VALUE;
    is_instrument = instr;
    midi_pitch = pitch;
    
    last_values_buffer = new float[LENGTH_OF_PAST_VALUES];
    for(int t=0; t<LENGTH_OF_PAST_VALUES; t++) {
      last_values_buffer[t] = 0.0;
    }
  }

  void update_min_and_max() {
    if(this.value < this.value_min) this.value_min = this.value;
    if(this.value > this.value_max) this.value_max = this.value;
    // println("DEBUG: min,max of #"+j+" are: "+this.value_min+","+this.value_max);
  }

  void update_past_value() {
    this.old_value = this.value;
  }
  
  void update_vector_of_past_values_for_hit_recording() {
    for(int t=LENGTH_OF_PAST_VALUES-1; t>0; t--) {
      this.last_values_buffer[t] = this.last_values_buffer[t-1];
    }
    this.last_values_buffer[0] = this.normalized_value();
  }

  float normalized_value() {
    // return zero if max and min values make no sense (i.e. are not set yet)
    if ((1.*this.value_max-this.value_min) <= 0) return 0;
    // if not, return so that min and max are top and bottom of window  
    return (1.*this.value-this.value_min) / (1.*this.value_max-this.value_min);
  }

  float normalized_old_value() {
    // return zero if max and min values make no sense (i.e. are not set yet)
    if ((1.*this.value_max-this.value_min) <= 0) return 0;
    // if not, return so that min and max are top and bottom of window  
    return (1.*this.old_value-this.value_min) / (1.*this.value_max-this.value_min);
  }
  
  void play_your_tone(float velocity, int channel_of_max_velocity) {
    new Tone(MIDI_CHANNEL,this.midi_pitch,round(127+127*this.velocity()),TONE_LENGTH,channel_of_max_velocity);
  }
  
  float velocity() {
    return abs(this.normalized_value() - this.normalized_old_value());
  }

}
