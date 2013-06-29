static class Phases
{
  static boolean Init = true;
  static boolean Recording = false; // should be equal to BAYESIAN_MODE_ENABLED
}

void update_phases()
{
  if(millis()/1000.0 > INIT_SECONDS) {
    Phases.Init = false;
  }
}
