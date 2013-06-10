class MovementOutcome {
  
  int serial_index;
  float[][] avg_target_move; // indices: [axis][time lag]
  float[][] std_target_move;
  int associated_signal_group;
  String label;
  boolean has_been_learned = false;
  int midi_pitch = -1;
  
  MovementOutcome(int serial, String l, int sigg, int pitch) {
    serial_index = serial;
    label = l;
    associated_signal_group = sigg;
    midi_pitch = pitch;
    
    avg_target_move = new float[NUMBER_OF_SIGNALS][LENGTH_OF_PAST_VALUES];
    std_target_move = new float[NUMBER_OF_SIGNALS][LENGTH_OF_PAST_VALUES];
  }
  
  float compute_bayesian_log_probability(int bayesian_length) {
    return this.compute_bayesian_log_probability( null, bayesian_length );
  }
  float compute_bayesian_log_probability(Hit event, int bayesian_length) {
    float prior = 1.0;
    float current_value;
    float log_probability = log(prior);
    for (int time_lag=0; time_lag<bayesian_length; time_lag++) {
      for (int axis_index=0; axis_index<NUMBER_OF_SIGNALS; axis_index++) {
        if(input.axis_dim[axis_index].signal_group == this.associated_signal_group) {
          // Compute the posterior probability according to independent normal distributions
          // for each involved axis (i.e. each axis of the associated signal group).
          if( event == null ) {
            current_value = input.axis_dim[axis_index].last_values_buffer[time_lag];
          } else { // if we want to compute the prob. of a pre-recorded hit
            current_value = event.value_history[axis_index][time_lag];
          }
          log_probability += StatisticsTools.log_Gauss_PDF( current_value, avg_target_move[axis_index][time_lag], std_target_move[axis_index][time_lag] );
        }
      }
    }
    // println("DEBUG: log. prob. of signal '"+this.label+"' = "+log_probability);
    return log_probability;
  }
  
  // void play_your_tone(float velocity) { this.play_your_tone(velocity, this.serial_index); }
  void play_your_tone(float velocity) {
    new Tone(MIDI_CHANNEL,this.midi_pitch,round(127*velocity),TONE_LENGTH,this.associated_signal_group,this.serial_index);
  }
  
  String status_information() {
    return this.label;
  }
  
}
