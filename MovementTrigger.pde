int WINDOW_LENGTH_FOR_MOVING_AVG_THRESHOLD = 20;

static class MovementTriggerTypes
{
  // old method: threshold on single axis slope
  static final int SingleThreshold = 0;
  // threshold on mean square slope (all axis simultaneously)
  static final int NormThreshold = 1;
  // threshold on difference between moving window average and mean square value (all axis simultaneously)
  static final int MovingAvergageNormThreshold = 2;
  
  static int cycle(int current) {
    return (current + 1) % 3; // not pretty, but works for now
  }
  
  static String explain(int current) {
    switch(current) {
      case SingleThreshold:
        return "SingleThreshold"; //" (old method, threshold on single axis slope)";
      case NormThreshold:
        return "NormThreshold"; // (threshold on mean square slope)";
      case MovingAvergageNormThreshold:
        return "MovingAvergageNormThreshold"; //: (threshold on difference between moving window average and mean square value)";
    }
    return "unknown trigger type (!)";
  }
}

class MovementTrigger
{
  int type;
  float xthreshold;
  
  MovementTrigger(int t) {
    type = t;
    xthreshold = 0.2;
  }
  
  int cycle_type() {
    return (type = MovementTriggerTypes.cycle(type));
  }
  
  String explain_type() {
    return MovementTriggerTypes.explain(type);
  }
  
  int detect(int signal_group) {
    if(input.group_is_already_playing_a_tone(signal_group)) {
      return -1;
    }
    float max_velocity = -1.0;
    int axis_of_max_velocity = 0;
    float velocity_here, value_here;
    
    switch(type) {
      case MovementTriggerTypes.SingleThreshold:
        for(int j=0; j<NUMBER_OF_SIGNALS; j++) {
          if(input.axis_dim[j].is_instrument && input.axis_dim[j].signal_group == signal_group) {
            velocity_here = input.axis_dim[j].velocity();
            if(velocity_here > max_velocity) {
              max_velocity = velocity_here;
              axis_of_max_velocity = j;
            }
          }
        }
        if(max_velocity > this.xthreshold) {
          return axis_of_max_velocity;
        }
        break;
      
      case MovementTriggerTypes.NormThreshold:
        float sum_of_velocities_squared = 0.0;
        for(int j=0; j<NUMBER_OF_SIGNALS; j++) {
          if(input.axis_dim[j].is_instrument && input.axis_dim[j].signal_group == signal_group) {
            velocity_here = input.axis_dim[j].velocity();
            // here it does not matter that velocity is already the absolute value
            sum_of_velocities_squared += pow(velocity_here, 2);
            if(velocity_here > max_velocity) {
              max_velocity = velocity_here;
              axis_of_max_velocity = j;
            }
          }
        }
        if(sqrt(sum_of_velocities_squared) > this.xthreshold) {
          return axis_of_max_velocity;
        }
        break;
      
      case MovementTriggerTypes.MovingAvergageNormThreshold:
        float sum_of_squared_deviations = 0.0;
        float past_average_value;
        for(int j=0; j<NUMBER_OF_SIGNALS; j++) {
          if(input.axis_dim[j].signal_group == signal_group) {
            value_here = input.axis_dim[j].normalized_value();
            velocity_here = input.axis_dim[j].velocity();
            past_average_value = input.axis_dim[j].average_of_last_values(WINDOW_LENGTH_FOR_MOVING_AVG_THRESHOLD);
            sum_of_squared_deviations += pow(value_here - past_average_value, 2);
            if(input.axis_dim[j].is_instrument) {
              if(velocity_here > max_velocity) {
                max_velocity = velocity_here;
                axis_of_max_velocity = j;
              }
            }
          }
        }
        if(sqrt(sum_of_squared_deviations) > this.xthreshold) {
          return axis_of_max_velocity;
        }
        break;
    }
    
    return -1;
  }
  
}
