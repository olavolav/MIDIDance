class Tone {
  int channel;
  int pitch;
  int velocity;
  float durationMS;
  float startMS;
  // int signal; // from which MIDI channel the tone was triggered
  int associated_signal_group; // from which signal group the tone was triggered
  
  Tone(int c, int p, int v, float d, int s, int outcome) {
    channel = c;
    pitch = p;
    velocity = v;
    durationMS = d;
    startMS = millis();
    associated_signal_group = s;
    // println("DEBUG: sending note with pitch "+pitch+" ...");
    myBus.sendNoteOn(channel, pitch, velocity);
    
    if(BAYESIAN_MODE_ENABLED && !currently_in_init_phase()) {
      new Hit(outcome, NULL_OUTCOME_FOR_SIGNAL_GROUP[associated_signal_group]);
    }
    
    // append it to the list of active tones unless there is one with same the parameters c,p
    boolean is_present = false;
    for(int m=0; m<activeTones.length; m++) {
      if(activeTones[m].channel == c && activeTones[m].pitch == p) {
        activeTones[m].velocity = v;
        activeTones[m].durationMS = d;
        activeTones[m].startMS = millis();
        activeTones[m].associated_signal_group = s;
        is_present = true;
      }
    }
    // println("debug in Tone: adding tone, is_present: "+int(is_present));
    if(!is_present) {
      Tone[] newActiveTones = new Tone[activeTones.length+1];
      for(int m=0; m<activeTones.length; m++) {
        newActiveTones[m] = activeTones[m];
      }
      newActiveTones[activeTones.length] = this;
      activeTones = newActiveTones;
    }
    // println("DEBUG: new number of active tones: "+activeTones.length);
  }
  
  void kill() {
    myBus.sendNoteOff(this.channel, this.pitch, this.velocity);
  }
}

void fadeOutTones() {
  Tone ton;
  for(int m=0; m<activeTones.length; m++) {
    ton = activeTones[m];
    if(millis()-ton.startMS > ton.durationMS) {
      // remove tone from list and kill it
      // println("debug in fadeOutTones: killing tone #"+m+", "+(activeTones.length-1)+" tones remaining active.");
      // myBus.sendNoteOff(ton.channel, ton.pitch, ton.velocity);
      ton.kill();
      Tone[] newActiveTones = new Tone[activeTones.length-1];
      int m_added = 0;
      for(int mm=0; mm<activeTones.length; mm++) {
        if(ton != activeTones[mm]) {
          newActiveTones[m_added] = activeTones[mm];
          m_added++;
        }
      }
      activeTones = newActiveTones;
    }
  }
}

// int get_channel_from_pitch(int pitch) {
//   int channel = -1;
//   for (int w=0; w<NUMBER_OF_SIGNALS; w++) {
//     if(MIDI_PITCH_CODES[w%(MIDI_PITCH_CODES.length)] == pitch) {
//       channel = w;
//       break;
//     }
//   }
//   return channel;
// }
