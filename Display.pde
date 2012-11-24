class Display {
  int rolling = 0;
  
  Display(int background_greylevel) {
    background(background_greylevel);
    textFont(createFont("LucidaGrande", 18));
  }
  
  void update_value_display() {
    String add_for_controller;
    textAlign(LEFT, CENTER);
    for(int j=0; j<NUMBER_OF_SIGNALS; j++) {
      if(input.axis_dim[j].is_instrument) add_for_controller = "";
      else add_for_controller = "(ctrl) ";

      fill(line_color(j),200);
      // text(add_for_controller+j+":\t "+input.axis_dim[j].value+", "+input.axis_dim[j].normalized_value(),10,20*j+10);
      text(add_for_controller+j+":\t "+input.axis_dim[j].value,10,20*j+10);
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
  
  void simple_blenddown(int alpha) {
    noSmooth();
    noStroke();
    fill(#000000, alpha);
    rect(0, 0, width, height);
    smooth();
  }
    
  void alert(String message) {
    textAlign(CENTER, CENTER);
    fill(#FFFFFF);
    text(message,width/2,height/2);
  }
  
}

color line_color(int j) {
  return LINE_COLORS[j%(LINE_COLORS.length)];
}
