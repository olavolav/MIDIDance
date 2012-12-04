
class MovementAnalyzer {
  
  MovementOutcome[] outcomes;
  float[] temp_detection_vector;
  
  MovementAnalyzer() {
    outcomes = new MovementOutcome[OUTCOMES_LABEL.length];
    for(int oo=0; oo<this.outcomes.length; oo++) {
      outcomes[oo] = new MovementOutcome(oo, OUTCOMES_LABEL[oo], SIGNAL_GROUP_OF_OUTCOME[oo], MIDI_PITCH_CODES[oo%(MIDI_PITCH_CODES.length)]);
    }
    
    temp_detection_vector = new float[MAX_NUMBER_OF_EVENTS_FOR_LEARNING];
  }
  
  boolean learn_based_on_recorded_hits() {
    int relevant_events_count;
    float mean_here, stddev_here;
    boolean all_models_could_be_learned = true;
    if(!LEARNING_MODE_ENABLED) {
      println("Warning: Learning mode disabled, so MovementAnalyzer#learn_based_on_recorded_hits() cannot work!");
      return false;
    }

    // println("DEBUG: collection:");
    // for (int events_index=0; events_index<collectedHits.length; events_index++) {
    //   println(" - event #"+events_index+" has target outcome "+collectedHits[events_index].target_outcome);
    // }
    // println(" --- end collection ---");
    
    for(int oo=0; oo<this.outcomes.length; oo++) {
      for (int time_lag=0; time_lag<LENGTH_OF_PAST_VALUES_FOR_BAYESIAN_ANALYSIS; time_lag++) {
        for (int axis_index=0; axis_index<NUMBER_OF_SIGNALS; axis_index++) {
          // temp_detection_vector = new float[0];
          relevant_events_count = 0;
          for (int events_index=0; events_index<collectedHits.length; events_index++) {
            if(relevant_events_count < MAX_NUMBER_OF_EVENTS_FOR_LEARNING) {
              if(collectedHits[events_index].target_outcome == oo) {
                temp_detection_vector[relevant_events_count] = collectedHits[events_index].value_history[axis_index][time_lag];
                relevant_events_count++;
              }
            }
          }
          if( relevant_events_count >= 2) {
            mean_here = this.__calculate_average_of_detection_vector(relevant_events_count);
            stddev_here = this.__calculate_standard_deviation_of_detection_vector(relevant_events_count);
            outcomes[oo].has_been_learned = true;
            outcomes[oo].avg_target_move[axis_index][time_lag] = mean_here;
            outcomes[oo].std_target_move[axis_index][time_lag] = stddev_here;
            // println("DEBUG: learned something for outcome #"+oo+" ("+outcomes[oo].label+") and axis #"+axis_index+" and time lag "+time_lag+": mean "+mean_here+", std. "+stddev_here);
          } else {
            // println("DEBUG: could not learn, not enough data.");
            all_models_could_be_learned = false;
          }
        }
      }
    }
    
    return all_models_could_be_learned;
  }
  
  private float __calculate_average_of_detection_vector(int count) {
    return StatisticsTools__mean(temp_detection_vector, 0, count-1);
  }

  private float __calculate_standard_deviation_of_detection_vector(int count) {
    return StatisticsTools__standard_deviation(temp_detection_vector, 0, count-1);
  }
  
  int detect(int triggering_signal_group) {
    int most_likely_outcome = NULL_OUTCOME_FOR_SIGNAL_GROUP[triggering_signal_group];
    float highest_log_probability = Float.MIN_VALUE;
    float log_probability;
    for(int oo=0; oo<this.outcomes.length; oo++) {
      if(this.outcomes[oo].associated_signal_group == triggering_signal_group) {
        log_probability = this.outcomes[oo].compute_bayesian_log_probability();
        if( log_probability > highest_log_probability ) {
          highest_log_probability = log_probability;
          most_likely_outcome = oo;
        }
      }
    }
    println("DEBUG: MovementAnalyzer#detect(): Most likely outcome = "+most_likely_outcome);
    return most_likely_outcome;
  }
  
  boolean load_target_movements_from_file() {
    println("Warning: MovementAnalyzer#load_target_movements_from_file() is not implemented yet!");
    return false;
  }

  boolean save_target_movements_to_file() {
    println("Warning: MovementAnalyzer#save_target_movements_to_file() is not implemented yet!");
    return false;
  }
  
  String status_of_recorded_hits_per_outcome() {
    String status = "";
    int[] counter_outcome = new int[this.outcomes.length];
    for(int oo=0; oo<this.outcomes.length; oo++) { counter_outcome[oo] = 0; }
    for (int hit_i=0; hit_i<collectedHits.length; hit_i++) { counter_outcome[collectedHits[hit_i].target_outcome] += 1; }
    for(int oo=0; oo<this.outcomes.length; oo++) {
      if( oo > 0 ) { status += ", "; }
      status += counter_outcome[oo]+" for #"+oo+" ("+this.outcomes[oo].label+")";
    }
    return status;
  }
  
}
