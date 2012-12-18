// Some statistics utility functions. Should at some point be packaged as
// a new object for namespace reasons.

float StatisticsTools__mean(float[] data, int start_index, int end_index) {
  if( data.length < end_index || end_index < start_index ) {
    println("error in StatisticsTools__mean: invalid paramters!");
    exit();
  }
  if( data.length == 0 ) {
    return 0.0;
  }
  
  float sum = 0.0;
  for (int i=start_index; i<=end_index; i++) {
    sum += data[i];
  }
  return sum/float(end_index-start_index+1);
}

float StatisticsTools__standard_deviation(float[] data, int start_index, int end_index) {
  float var = StatisticsTools__variance(data, start_index, end_index);
  if(var < 0.0) { return -1.0; }
  return sqrt(StatisticsTools__variance(data, start_index, end_index));
}

float StatisticsTools__variance(float[] data, int start_index, int end_index) {
  if( data.length < end_index || end_index <= start_index ) {
    println("error in StatisticsTools__variance: invalid paramters!");
    exit();
  }
  if( data.length == 0 ) {
    return 0.0;
  }
  boolean all_identical = true;
  for (int i=start_index+1; i<=end_index; i++) {
    if( data[i-1] != data[i] ) {
      all_identical = false;
      break;
    }
  }
  if( all_identical ) {
    // println("error in StatisticsTools__variance: variance of vector is zero!");
    // exit();
    // Variance zero happens too frequently, we instead return an arbitrary constant number:
    println("Warning in StatisticsTools__variance: variance of vector is zero!");
    return 0.1;
  }
  
  float mean = StatisticsTools__mean(data, start_index, end_index);
  float sum = 0.0;
  for(int i=start_index; i<=end_index; i++) {
    sum += pow(data[i] - mean, 2);
  }
  return sum/float(end_index-start_index+1);
}
