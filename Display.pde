class Display {
  int rolling = 0;
  
  Display(int background_greylevel) {
    background(background_greylevel);
    textFont(createFont("LucidaGrande", 18));
  }
  
  void update_value_display() {
    String label;
    textSize(20);
    textAlign(LEFT, CENTER);
    for(int j=0; j<NUMBER_OF_SIGNALS; j++) {
      label = AXIS_LABELS[j%(AXIS_LABELS.length)];
      if(!input.axis_dim[j].is_instrument) label += " (ctrl)";
      
      fill(line_color(j),200);
      text(label+" #"+j+": "+input.axis_dim[j].value,10,20*j+10);
    }
  }
  
  void update_graphs() {
    // display values as graph
    rolling = (rolling+ROLLING_INCREMENT)%width;
    strokeWeight(2);
    for(j=0; j<NUMBER_OF_SIGNALS; j++) {
      stroke(line_color(j), 200);
      line(this.rolling, round(height*input.axis_dim[j].normalized_old_value()), this.rolling+ROLLING_INCREMENT,
        round(height*input.axis_dim[j].normalized_value()));
    }
  }
  
  void draw_vertical_line(int axis_nr) {
    stroke( line_color(axis_nr), 200 );
    line( this.rolling+ROLLING_INCREMENT,0,this.rolling+ROLLING_INCREMENT,height);
  }
  
  void simple_blenddown(int alpha) {
    noSmooth();
    noStroke();
    fill(#000000, alpha);
    rect(0, 0, width, height);
    smooth();
  }
    
  void alert(String message) {
    textSize(20);
    textAlign(CENTER, CENTER);
    fill(#FFFFFF);
    text(message,width/2,height/2);
  }

  void huge_alert(String message) {
    textSize(200);
    textAlign(CENTER, CENTER);
    fill(#FFFFFF);
    text(message,width/2,height/2);
  }
  
  void draw_progress_bar(float fraction) {
    float bounded_fraction = min( 1.0, max(0.0, fraction) );
    noSmooth();
    noFill();
    stroke(#ffffff);
    rect(width/4.0, height*0.666, round(width/2.0)+1, height/20.0);
    noStroke();
    fill(#ffffff);
    rect(width/4.0, height*0.666, round(bounded_fraction*width/2.0)+1, height/20.0);
  }
  
}

color line_color(int j) {
  return LINE_COLORS[j%(LINE_COLORS.length)];
}
