class Tone {
  int channel;
  int pitch;
  int velocity;
  float durationMS;
  float startMS;
  int signal; // from which MIDI channel the tone was triggered
  
  Tone(int c, int p, int v, float d, int s) {
    channel = c;
    pitch = p;
    velocity = v;
    durationMS = d;
    startMS = millis();
    signal = s;
    // println("DEBUG: sending note with pitch "+pitch+" ...");
    myBus.sendNoteOn(channel, pitch, velocity);
    // append it to the list of active tones unless there is one with same the parameters c,p
    boolean is_present = false;
    for(int m=0; m<activeTones.length; m++) {
      if(activeTones[m].channel == c && activeTones[m].pitch == p) {
        activeTones[m].velocity = v;
        activeTones[m].durationMS = d;
        activeTones[m].startMS = millis();
        activeTones[m].signal = s;
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
