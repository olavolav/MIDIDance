int accOnexPin = 0;
int accOneyPin = 1;
int accOnezPin = 2;
int accTwoxPin = 4;
int accTwoyPin = 3;
int accTwozPin = 5;

int valOnex = 0;
int valOney = 0;
int valOnez = 0;
int valTwox = 0;
int valTwoy = 0;
int valTwoz = 0;
int checksumOne = 0;
int checksumTwo = 0;
int sensorLabelOne = 1;
int sensorLabelTwo = 2;

void setup () {
  Serial.begin(9600);
}

void loop() {
  valOnex =analogRead(accOnexPin);
  valOney =analogRead(accOneyPin);
  valOnez = analogRead(accOnezPin);
  valTwox =analogRead(accTwoxPin);
  valTwoy =analogRead(accTwoyPin);
  valTwoz = analogRead(accTwozPin);

 checksumOne = valOnex+valOney+valOnez;
 checksumTwo = valTwox+valTwoy+valTwoz;
 String valOnexstring = String(valOnex,DEC);
 String valOneystring = String(valOney,DEC);
 String valOnezstring = String(valOnez,DEC);
 String valTwoxstring = String(valTwox,DEC);
 String valTwoystring = String(valTwoy,DEC);
 String valTwozstring = String(valTwoz,DEC);
Serial.print("<");
Serial.print(sensorLabelOne, DEC);
Serial.print(",");
Serial.print(valOnexstring, DEC);
Serial.print(",");
Serial.print(valOnexstring, DEC);
Serial.print(",");
Serial.print(valOnexstring, DEC);
Serial.print(",");
Serial.print(checksum, DEC);
Serial.println(">");

Serial.print("<");
Serial.print(sensorLabelTwo, DEC);
Serial.print(",");
Serial.print(valTwoxstring, DEC);
Serial.print(",");
Serial.print(valTwoxstring, DEC);
Serial.print(",");
Serial.print(valTwoxstring, DEC);
Serial.print(",");
Serial.print(checksum, DEC);
Serial.println(">");

//  // Finish by adding the sum as a crude "checksum"
//Serial.print(",");
//Serial.print(checksum, DEC);
//Serial.println(">");
 //Serial.println("<" + sensorLabelOne + "," + valOnexstring + "," + valOneystring + "," + valOnezstring + "," + checksumOne + ">",DEC); 
 //Serial.println("<" + sensorLabelTwo + "," + valTwoxstring + "," + valTwoystring + "," + valTwozstring + "," + checksumTwo + ">",DEC); 
// Serial.println(valx,DEC)
// print(",")
//  Serial.print(valy,DEC)
//  print(",")
//   Serial.print(valz,DEC)
// + "," + valy + "," + valz, DEC);
  //Serial.println(valz, DEC);
  delay(10);
}
