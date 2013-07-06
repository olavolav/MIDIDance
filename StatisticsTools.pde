// Some statistics utility functions. Should at some point be packaged as
// a new object for namespace reasons.

static class StatisticsTools
{
  static float mean(float[] data, int start_index, int end_index) {
    if( data.length < end_index || end_index < start_index ) {
      println("Error in StatisticsTools::mean: invalid paramters!");
      // exit();
      return 0.0;
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

  static float standard_deviation(float[] data, int start_index, int end_index) {
    float var = variance(data, start_index, end_index);
    if(var < 0.0) { return -1.0; }
    return sqrt(var);
  }

  static float variance(float[] data, int start_index, int end_index) {
    if( data.length < end_index || end_index <= start_index ) {
      println("error in StatisticsTools::variance: invalid paramters!");
      // exit();
      return 0.0;
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
      println("Warning in StatisticsTools::variance: variance of vector is zero!");
      return 0.1;
    }
  
    float mean = mean(data, start_index, end_index);
    float sum = 0.0;
    for(int i=start_index; i<=end_index; i++) {
      sum += pow(data[i] - mean, 2);
    }
    return sum/float(end_index-start_index+1);
  }

  static float log_Gauss_PDF(float x, float mean, float stddev) {
    return ( -1.0*log(stddev * sqrt(2.0*PI)) - 0.5*pow( (x - mean)/stddev, 2.0) );
  }
  
}
