// Arduino Joystick to Processing
const int SW = 4;
const int VRx = A1;
const int VRy = A2;
bool lastButton = false;

int lastDir = 0;   // 0=none, 1=UP, 2=DOWN, 3=LEFT, 4=RIGHT

#include "Arduino_LED_Matrix.h"  // Include the Arduino LED Matrix library

ArduinoLEDMatrix matrix;

//  LED Pattern
uint8_t snakePattern[8][12] = {
  {0,0,0,1,0,0,0,0,1,0,0,0},
  {0,0,0,0,1,1,1,1,0,0,0,0},
  {0,0,0,1,1,1,1,1,1,0,0,0},
  {0,0,1,1,0,1,1,0,1,1,0,0},
  {0,0,1,1,1,1,1,1,1,1,0,0},
  {0,0,0,1,1,0,0,1,1,0,0,0},
  {0,0,1,0,1,0,0,1,0,1,0,0},
  {0,0,1,0,0,0,0,0,0,1,0,0}
};

void setup() {
  Serial.begin(9600);
  pinMode(SW, INPUT_PULLUP);

  matrix.begin();
}

/* void loop() {
  int x = analogRead(VRx); // X-axis
  int y = analogRead(VRy); // Y-axis
  bool swPressed = (digitalRead(SW) == LOW);

  // LED pattern
  matrix.renderBitmap(snakePattern, 8, 12);

  // Determine direction
  String direction = "";

  if (x < 400) {
    direction = "UP";
  } else if (x > 600) {
    direction = "DOWN";
  } else if (y < 400) {
    direction = "RIGHT";
  } else if (y > 600) {
    direction = "LEFT";
  }

  // Send only ONE direction per loop
  if (direction.length() > 0) {
    Serial.println(direction);
  }

  ///if (direction != "") {
  ///  Serial.println(direction); // Send direction to Processing
  ///}

  if (swPressed && !lastButton) {
    Serial.println("BTN");  // <-- send "BTN" to Processing
  }
  lastButton = swPressed;

  delay(25); // Adjust for game speed
} */

void loop() {
  int x = analogRead(VRx);
  int y = analogRead(VRy);
  int sw = digitalRead(SW);

  // LED pattern
  matrix.renderBitmap(snakePattern, 8, 12);

  // -------- BUTTON ------------ //
  if (sw == LOW && lastButton == HIGH) {
    Serial.println("BTN");
  }
  lastButton = sw;

  // -------- DEAD ZONE --------- //
  const int low = 450;
  const int high = 570;

  int dir = 0;

  // Only commit to a direction if value is WELL outside center
  if (x < low)  dir = 3;  // LEFT
  else if (x > high) dir = 4;  // RIGHT
  else if (y < low)  dir = 1;  // UP
  else if (y > high) dir = 2;  // DOWN
  else dir = 0;  // neutral

  // -------- SEND ONLY IF CHANGED -------- //
  if (dir != 0 && dir != lastDir) {
    if (dir == 1) Serial.println("RIGHT");
    if (dir == 2) Serial.println("LEFT");
    if (dir == 3) Serial.println("UP");
    if (dir == 4) Serial.println("DOWN");
  }

  lastDir = dir;

  if (sw && !lastButton) {
    Serial.println("BTN");  // <-- send "BTN" to Processing
  }
  lastButton = sw;

  delay(25);
}


