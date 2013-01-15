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
    // boolean all_models_could_be_learned = true;
    if(!BAYESIAN_MODE_ENABLED) {
      println("Warning: Learning mode disabled, so MovementAnalyzer#learn_based_on_recorded_hits() cannot work!");
      return false;
    }

    for(int oo=0; oo<this.outcomes.length; oo++) {
      if( SKIP_OUTCOME_WHEN_EVALUATING_BAYESIAN_DETECTOR[oo] == false ) {
        // We compute the models for the maximum vector length, and find
        // the optimal length later.
        for (int time_lag=0; time_lag<LENGTH_OF_PAST_VALUES; time_lag++) {
          for (int axis_index=0; axis_index<NUMBER_OF_SIGNALS; axis_index++) {
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
              if( stddev_here < 0.0 ) {
                // all_models_could_be_learned = false;
                return false;
              }
              outcomes[oo].has_been_learned = true;
              outcomes[oo].avg_target_move[axis_index][time_lag] = mean_here;
              outcomes[oo].std_target_move[axis_index][time_lag] = stddev_here;
              // println("DEBUG: learned something for outcome #"+oo+" ("+outcomes[oo].label+") and axis #"+axis_index+" and time lag "+time_lag+": mean "+mean_here+", std. "+stddev_here);
            } else {
              // all_models_could_be_learned = false;
              return false;
            }
          }
        }
      }
    }
    
    return true; //all_models_could_be_learned;
  }
  
  private float __calculate_average_of_detection_vector(int count) {
    return StatisticsTools__mean(temp_detection_vector, 0, count-1);
  }

  private float __calculate_standard_deviation_of_detection_vector(int count) {
    return StatisticsTools__standard_deviation(temp_detection_vector, 0, count-1);
  }
  
  int detect(int triggering_signal_group) {
    return this.detect(triggering_signal_group, optimal_bayesian_vector_length, null);
  }
  int detect(int triggering_signal_group, int bayesian_length) {
    return this.detect(triggering_signal_group, bayesian_length, null);
  }
  int detect(int triggering_signal_group, int bayesian_length, Hit event) {
    int most_likely_outcome = NULL_OUTCOME_FOR_SIGNAL_GROUP[triggering_signal_group];
    float highest_log_probability = -0.5*Float.MAX_VALUE;
    float log_probability;
    for(int oo=0; oo<this.outcomes.length; oo++) {
      if( SKIP_OUTCOME_WHEN_EVALUATING_BAYESIAN_DETECTOR[oo] == false ) {
        if(this.outcomes[oo].associated_signal_group == triggering_signal_group) {
          log_probability = this.outcomes[oo].compute_bayesian_log_probability( event, bayesian_length );
          if( log_probability > highest_log_probability ) {
            highest_log_probability = log_probability;
            most_likely_outcome = oo;
          }
        }
      }
    }
    // println("DEBUG: MovementAnalyzer#detect: Most likely outcome = "+most_likely_outcome);
    return most_likely_outcome;
  }
  
  float detect_accuracy_of_all_prerecorded_hits_and_determine_optimal_length() {
    int optimal_length_found = -1;
    float optimal_accuracy_found = -0.5*Float.MAX_VALUE;
    float accuracy_found;
    for(int l=1; l<LENGTH_OF_PAST_VALUES; l++) {
      accuracy_found = detect_accuracy_of_all_prerecorded_hits( l, true );
      if( accuracy_found > optimal_accuracy_found ) {
        optimal_accuracy_found = accuracy_found;
        optimal_length_found = l;
      }  
      screen.draw_progress_bar( (1.0*l)/(LENGTH_OF_PAST_VALUES-1.0) );
      if( accuracy_found == 1.0 ) {
        println("...reached 100% accuracy.");
        break;
      }
    }
    if( optimal_accuracy_found > 0.0 ) {
      optimal_bayesian_vector_length = optimal_length_found;
      println("=> Found optimal projected accuracy of "+optimal_accuracy_found+" at optimal length "+optimal_length_found);
    }
    return optimal_accuracy_found;
  }
  float detect_accuracy_of_all_prerecorded_hits(int bayesian_length) {
    return detect_accuracy_of_all_prerecorded_hits( bayesian_length, false );
  }
  float detect_accuracy_of_all_prerecorded_hits(int bayesian_length, boolean verbose) {
    int[] relevant_for_this = new int[this.outcomes.length];
    int[] correct_for_this = new int[this.outcomes.length];
    for (int oo=0; oo<this.outcomes.length; oo++) {
      relevant_for_this[oo] = 0;
      correct_for_this[oo] = 0;
    }
    int relevant_hits = 0;
    int correct_hits = 0;
    if( collectedHits.length == 0 ) { return 0.0; }
    int tt;
    for(int h=0; h<collectedHits.length; h++) {
      tt = collectedHits[h].target_outcome;

      if( SKIP_OUTCOME_WHEN_EVALUATING_BAYESIAN_DETECTOR[tt] == false ) {
        // println("DEBUG in detect_accuracy_of_all_prerecorded_hits: target outcome of hit #"+h+" is #"+tt);
        relevant_hits++;
        relevant_for_this[tt]++;
        if( tt == this.detect( SIGNAL_GROUP_OF_OUTCOME[tt], bayesian_length, collectedHits[h]) ) {
          // println("DEBUG in detect_accuracy_of_all_prerecorded_hits: hit #"+h+" would be correctly identified.");
          correct_hits++;
          correct_for_this[tt]++;
        } else {
          // println("DEBUG in detect_accuracy_of_all_prerecorded_hits: hit #"+h+" would be incorrectly identified.");
        }
      }
    }
    
    if(verbose) {
      println("------ Learning performance overview (length "+bayesian_length+") ------");
      for (int oo=0; oo<this.outcomes.length; oo++) {
        print(" - outcome #"+oo+" ("+this.outcomes[oo].label+"): ");
        if( SKIP_OUTCOME_WHEN_EVALUATING_BAYESIAN_DETECTOR[oo] == false ) {
          print( (100.0*float(correct_for_this[oo])/float(relevant_for_this[oo]))+"%" );
          println( " (based on "+relevant_for_this[oo]+" target hits)");
        } else {
          println("skipped.");
        }
      }
    }
    println("DEBUG: projected accuracy for length "+bayesian_length+" = "+float(correct_hits)/float(relevant_hits));
    
    return float(correct_hits)/float(relevant_hits);
  }
    
  String status_of_recorded_hits_per_outcome() {
    String status = "";
    int[] counter_outcome = new int[this.outcomes.length];
    for(int oo=0; oo<this.outcomes.length; oo++) { counter_outcome[oo] = 0; }
    for(int hit_i=0; hit_i<collectedHits.length; hit_i++) { counter_outcome[collectedHits[hit_i].target_outcome] += 1; }
    for(int oo=0; oo<this.outcomes.length; oo++) {
      if( oo > 0 ) { status += ", "; }
      status += counter_outcome[oo]+" for #"+oo+" ("+this.outcomes[oo].label+")";
    }
    return status;
  }
  
}
