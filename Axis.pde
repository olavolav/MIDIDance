class Axis
{
  int value;
  int value_min, value_max;
  int signal_group = 0;
  boolean is_instrument = true;
  float[] last_values_buffer;

  Axis(boolean instr, int sg) {
    value = 0;
    value_min = Integer.MAX_VALUE;
    value_max = Integer.MIN_VALUE;
    is_instrument = instr;
    signal_group = sg;
    
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

  void update_vector_of_past_values() {
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
    return this.last_values_buffer[1];
  }
  
  float velocity() {
    return abs(this.normalized_value() - this.normalized_old_value());
  }
  
  float average_of_last_values(int length) {
    if(length < 1) { return 0.0; }
    float sum = 0.0;
    int actual_length = max(length, LENGTH_OF_PAST_VALUES-1);
    for(int t=1; t<=actual_length; t++) {
      sum += this.last_values_buffer[t];
    }
    return sum/actual_length;
  }

}
