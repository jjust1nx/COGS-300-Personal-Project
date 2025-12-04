#include <Keyboard.h>

const int joyX = A1; 
const int joyY = A2;
const int joySW = 4;

const int ledPin = 9;

int potPin = A0;

// State trackers
bool lastDuck = false;
bool lastButton = false;

// Deadzone values
const int centerMin = 460;
const int centerMax = 560;

// Thresholds for actions
const int upThreshold = 300;    // joystick pushed UP
const int downThreshold = 700;  // joystick pushed DOWN

void setup() {
  pinMode(joySW, INPUT_PULLUP);   // joystick button (active low)
  pinMode(ledPin, OUTPUT);

  Keyboard.begin();
  Serial.begin(9600);
}

void loop() {
  // -----------------------------
  //   Potentiometer to Processing
  // -----------------------------
  int potVal = analogRead(potPin);
  Serial.println(potVal);   // Processing reads this for volume
  delay(10);

  // -----------------------------
  //   Joystick Reading
  // -----------------------------
  int xVal = analogRead(joyX);
  bool swPressed = (digitalRead(joySW) == LOW);

  bool jumpTriggered = false;

  // -----------------------------
  //   JOYSTICK UP → JUMP
  // -----------------------------
  if (xVal < upThreshold) {
    // Only fire jump once per push upward
    if (!jumpTriggered) {
      Keyboard.press(' ');
      delay(5);
      Keyboard.release(' ');
      jumpTriggered = true;
    }
  }

  // -----------------------------
  //   JOYSTICK DOWN → DUCK (hold)
  // -----------------------------
  bool duckNow = (xVal > downThreshold);

  if (duckNow && !lastDuck) {
    Keyboard.press(KEY_DOWN_ARROW);
  } 
  else if (!duckNow && lastDuck) {
    Keyboard.release(KEY_DOWN_ARROW);
  }
  lastDuck = duckNow;

  // -----------------------------
  //   JOYSTICK BUTTON → RESTART GAME
  //   Only presses UP arrow once per click
  // -----------------------------
  if (swPressed && !lastButton) {
    Keyboard.press(KEY_UP_ARROW);   // restart game
    delay(5);
    Keyboard.release(KEY_UP_ARROW);
  }
  lastButton = swPressed;

  delay(1);
}
