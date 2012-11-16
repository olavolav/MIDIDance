class Axis {
  int value;
  int old_value, temp_value;
  int value_min, value_max;
  int signal_group = 0;
  boolean is_instrument = true;
  int midi_pitch = -1;

  Axis(boolean instr, int pitch) {
    value = 0;
    old_value = 0;
    value_min = Integer.MAX_VALUE;
    value_max = Integer.MIN_VALUE;
    is_instrument = instr;
    if(is_instrument) midi_pitch = pitch;
  }

  void update_min_and_max() {
    if(this.value < this.value_min) this.value_min = this.value;
    if(this.value > this.value_max) this.value_max = this.value;
    // println("DEBUG: min,max of #"+j+" are: "+this.value_min+","+this.value_max);
  }

  void update_past_value() {
    old_value = value;
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

}
