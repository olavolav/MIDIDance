class Hit
{
  int actual_outcome;
  int target_outcome;
  float startMS;
  float[] velocity_values;
  float[][] value_history;
  
  Hit(int out, int target_out) {
    actual_outcome = out;
    target_outcome = target_out;
    // println("DEBUG: creating a Hit object: actual_outcome = "+actual_outcome+", target_outcome = "+target_outcome);
    startMS = millis();
    
    // store velocity values for later
    velocity_values = new float[NUMBER_OF_SIGNALS];
    for(int m=0; m<NUMBER_OF_SIGNALS; m++) {
      velocity_values[m] = input.axis_dim[m].velocity();
    }
    
    // store recent history of signal for each axis
    value_history = new float[NUMBER_OF_SIGNALS][LENGTH_OF_PAST_VALUES];
    for(int m=0; m<NUMBER_OF_SIGNALS; m++) {
      for(int n=0; n<LENGTH_OF_PAST_VALUES; n++) {
        value_history[m][n] = input.axis_dim[m].last_values_buffer[n];
      }
    }
    
    // add this hit to list
    collectedHits = (Hit[])append(collectedHits, this);
  }
  
  boolean was_correctly_identified() {
    return (this.actual_outcome == this.target_outcome);
  }
  
  String status_information() {
    String text = this.startMS+", "+this.actual_outcome+", "+this.target_outcome;
    for(int m=0; m<NUMBER_OF_SIGNALS; m++) {
      for(int n=0; n<LENGTH_OF_PAST_VALUES; n++) {
        text += ", "+this.value_history[m][n];
      }      
    }
    return text;
  }
}


float accuracy_of_past_hits() {
  if(collectedHits.length == 0) return 0.0;

  int exact_count = 0;
  for(int m=0; m<collectedHits.length; m++) {
    if(collectedHits[m].was_correctly_identified()) exact_count++;
  }
  
  return float(exact_count)/float(collectedHits.length);
}
