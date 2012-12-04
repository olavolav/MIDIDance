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
    
    avg_target_move = new float[NUMBER_OF_SIGNALS][LENGTH_OF_PAST_VALUES_FOR_BAYESIAN_ANALYSIS];
    std_target_move = new float[NUMBER_OF_SIGNALS][LENGTH_OF_PAST_VALUES_FOR_BAYESIAN_ANALYSIS];
  }
  
  float compute_bayesian_log_probability() { return this.compute_bayesian_log_probability(1.0); }
  float compute_bayesian_log_probability(float prior) {
    float log_probability = log(prior);
    for (int time_lag=0; time_lag<LENGTH_OF_PAST_VALUES_FOR_BAYESIAN_ANALYSIS; time_lag++) {
      for (int axis_index=0; axis_index<NUMBER_OF_SIGNALS; axis_index++) {
        if(input.axis_dim[axis_index].signal_group == this.associated_signal_group) {
          // Compute the posterior probability according to independent normal distributions
          // for each involved axis (i.e. each axis of the associated signal group).
          // log_probability += log( 1.0/(std_target_move[axis_index][time_lag]*sqrt(2.0*PI)) * exp( -0.5*pow( (input.axis_dim[axis_index].last_values_buffer[time_lag] - avg_target_move[axis_index][time_lag]) / std_target_move[axis_index][time_lag], 2.0) ) );
          log_probability += -1.0*log(std_target_move[axis_index][time_lag]*sqrt(2.0*PI)) - 0.5*pow( (input.axis_dim[axis_index].last_values_buffer[time_lag] - avg_target_move[axis_index][time_lag]) / std_target_move[axis_index][time_lag], 2.0);
          
        }
      }
    }
    println("DEBUG: log. prob. of signal '"+this.label+"' = "+log_probability);
    return log_probability;
  }
  
  // void play_your_tone(float velocity) { this.play_your_tone(velocity, this.serial_index); }
  void play_your_tone(float velocity) {
    new Tone(MIDI_CHANNEL,this.midi_pitch,round(127*velocity),TONE_LENGTH,this.associated_signal_group,this.serial_index);
  }
  
}
