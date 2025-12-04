
#include <Keyboard.h>

const int jumpPin = 2;   // Button 1
const int duckPin = 3;   // Button 2
const int ledPin = 9;  // LED pin

bool lastJump = LOW;
bool lastDuck = LOW;

bool blinkActive = false;
int blinkCount = 0;
unsigned long lastToggle = 0;
bool ledState = LOW;

int potPin = A0; // analog input

void setup() {
  pinMode(jumpPin, INPUT);  // Using external pull-down wiring
  pinMode(duckPin, INPUT);
  pinMode(ledPin, OUTPUT); // LED

  Keyboard.begin();
  Serial.begin(9600);
}

// Helper function to blink LED 3 times
void blinkLED3Times() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(ledPin, HIGH);
    delay(200);
    digitalWrite(ledPin, LOW);
    delay(200);
  }
}

void loop() {
  int val = analogRead(potPin); // 0–1023
  Serial.println(val);
  delay(50); // ~20 readings/sec

  bool jumpPressed = (digitalRead(jumpPin) == HIGH);
  bool duckPressed = (digitalRead(duckPin) == HIGH);

  // --- JUMP BUTTON (momentary press = spacebar) ---
  if (jumpPressed && lastJump == LOW) {
    Keyboard.press(' ');
    delay(5);
    Keyboard.release(' ');
  }
  lastJump = jumpPressed;

  // --- DUCK BUTTON (hold = down arrow) ---
  if (duckPressed && lastDuck == LOW) {
    Keyboard.press(KEY_DOWN_ARROW);
  }
  else if (!duckPressed && lastDuck == HIGH) {
    Keyboard.release(KEY_DOWN_ARROW);
  }
  lastDuck = duckPressed;

if (Serial.available()) {
    String msg = Serial.readStringUntil('\n');
    msg.trim();
    if (msg == "BLINK" && !blinkActive) {  // start blink only if not already blinking
      blinkActive = true;
      blinkCount = 0;
      ledState = LOW;
      digitalWrite(ledPin, LOW);
      lastToggle = millis();
    }
  }

  // --- Handle non-blocking LED blink ---
  if (blinkActive) {
    if (millis() - lastToggle >= 200) {  // 200ms per on/off
      ledState = !ledState;
      digitalWrite(ledPin, ledState ? HIGH : LOW);
      lastToggle = millis();

      if (!ledState) blinkCount++;  // count full on/off cycles
      if (blinkCount >= 3) blinkActive = false;  // done after 3 blinks
    }
  }

  delay(1);
}

