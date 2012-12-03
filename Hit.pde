class Hit {
  int channel;
  int target_channel = -1;
  float startMS;
  float[] velocity_values;
  float[][] value_history;
  
  Hit(int ch) {
    channel = get_channel_from_pitch(ch);
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
    Hit[] newCollectedHits = new Hit[collectedHits.length+1];
    for(int m=0; m<collectedHits.length; m++) {
      newCollectedHits[m] = collectedHits[m];
    }
    newCollectedHits[collectedHits.length] = this;
    collectedHits = newCollectedHits;
    
  }
  
  boolean was_correctly_identified() {
    return (this.channel == this.target_channel);
  }
  
  String status_information() {
    String text = startMS+", "+channel+", "+target_channel;
    for(int m=0; m<NUMBER_OF_SIGNALS; m++) {
      // text += ", "+this.velocity_values[m];
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