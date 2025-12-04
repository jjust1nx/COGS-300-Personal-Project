#include <Keyboard.h>
#include "Arduino_LED_Matrix.h"

// -----------------------------
// MODE VARIABLES
// -----------------------------
int currentMode = 1;       // 1 = Dino, 2 = Snake
const int totalModes = 2;  
unsigned long flashUntil = 0;
bool flashing = false;

// -----------------------------
// DINO + SNAKE JOYSTICK & GAME VARIABLES
// -----------------------------
const int joyX = A1; 
const int joyY = A2;
const int joySW = 4;
int lastDir = 0;

bool lastDuck = false;
bool lastButtonDino = false;
bool lastButtonSnake = false;

// Deadzone / thresholds
const int centerMin = 460;
const int centerMax = 560;
const int upThreshold = 300;    // joystick pushed UP
const int downThreshold = 700;  // joystick pushed DOWN

// -----------------------------
// MENU JOYSTICK & MATRIX
// -----------------------------
const int menuSW = 5;
const int VRx = A3;
const int VRy = A4;
bool lastButtonMenu = false;

ArduinoLEDMatrix matrix;

// LED Pattern for Snake
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

// LED Pattern for Dino
uint8_t dinoPattern[8][12] = {
  {0,0,1,0,0,1,1,0,0,1,0,0},
  {0,0,1,0,1,1,1,1,0,1,0,0},
  {0,0,0,1,0,1,1,0,1,0,0,0},
  {0,0,0,1,1,1,1,1,1,0,0,0},
  {0,0,0,1,0,0,0,0,1,0,0,0},
  {0,0,0,0,1,1,1,1,0,0,0,0},
  {0,0,1,1,0,1,1,0,1,1,0,0},
  {0,0,1,0,0,0,0,0,0,1,0,0}
};

// LED Pattern for LEFT
uint8_t leftPattern[8][12] = {
  {0,0,0,1,0,0,0,0,0,0,0,0},
  {0,0,1,1,0,0,0,0,0,0,0,0},
  {0,1,1,1,0,0,0,0,0,0,0,0},
  {1,1,1,1,1,1,1,1,0,0,0,0},
  {0,1,1,1,0,0,0,0,0,0,0,0},
  {0,0,1,1,0,0,0,0,0,0,0,0},
  {0,0,0,1,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0}
};

// LED Pattern for UP
uint8_t upPattern[8][12] = {
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,0,0,1,1,1,0,0,0,0,0},
  {0,0,0,1,1,1,1,1,0,0,0,0},
  {0,0,1,1,1,1,1,1,1,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0}
};

// LED Pattern for DOWN
uint8_t downPattern[8][12] = {
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0},
  {0,0,1,1,1,1,1,1,1,0,0,0},
  {0,0,0,1,1,1,1,1,0,0,0,0},
  {0,0,0,0,1,1,1,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0}
};

// LED Pattern for RIGHT
uint8_t rightPattern[8][12] = {
  {0,0,0,0,0,0,0,0,1,0,0,0},
  {0,0,0,0,0,0,0,0,1,1,0,0},
  {0,0,0,0,0,0,0,0,1,1,1,0},
  {0,0,0,0,1,1,1,1,1,1,1,1},
  {0,0,0,0,0,0,0,0,1,1,1,0},
  {0,0,0,0,0,0,0,0,1,1,0,0},
  {0,0,0,0,0,0,0,0,1,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0}
};

// LED Pattern for RESET
uint8_t resetPattern[8][12] = {
  {0,0,1,1,1,1,1,1,1,0,0,0},
  {0,1,0,0,0,0,0,0,1,0,0,0},
  {0,1,0,0,0,0,0,0,1,0,0,0},
  {0,1,0,0,0,1,1,1,1,1,1,1},
  {0,1,0,0,0,0,1,1,1,1,1,0},
  {0,1,0,0,0,0,0,1,1,1,0,0},
  {0,1,0,0,0,0,0,0,1,0,0,0},
  {0,0,1,1,1,1,1,1,0,0,0,0}
};

uint8_t (*currentPattern)[12] = dinoPattern;  // default pattern

// -----------------------------
// SETUP
// -----------------------------
void setup() {
  Serial.begin(9600);
  Keyboard.begin();

  // Game
  pinMode(joySW, INPUT_PULLUP);

  // Menu
  pinMode(menuSW, INPUT_PULLUP);
  matrix.begin();

  Serial.println("System ready. Default mode: DINO");
}

void loop() {
  handleMenuJoystick();  // switch modes & read button
  handleGameMode();      // run the selected game
}

// -----------------------------
// Menu joystick handling
// -----------------------------
void handleMenuJoystick() {
  int y = analogRead(VRy);
  int sw1 = digitalRead(menuSW);

  // LEFT → Dino
  if (y > 570 && currentMode != 1) {
    currentMode = 1;
    Serial.println("DINO");
  }
  // RIGHT → Snake
  else if (y < 450 && currentMode != 2) {
    currentMode = 2;
    Serial.println("SNAKE");
  }

  // Menu button press (to start game)
  if (sw1 == LOW && lastButtonMenu == HIGH) {
    Serial.println("START");
  }
  lastButtonMenu = sw1;
}

// -----------------------------
// Run selected game
// -----------------------------
void handleGameMode() {
  if (currentMode == 1) {
    runDino();   // your existing Dino joystick/game code
  } else if (currentMode == 2) {
    lastDir = 0;
    runSnake();  // your existing Snake joystick/game code
  }
}
// -----------------------------
// DINO MODE FUNCTION
// -----------------------------
void runDino() {

// -----------------------------
  //   Joystick Reading
  // -----------------------------
  int xVal = analogRead(joyX);
  bool swPressed = (digitalRead(joySW) == LOW);
  unsigned long now = millis();

  bool jumpTriggered = false;
  
  // ----------------------------------
  // Restore main pattern after flash
  // ----------------------------------
  if (flashing && now >= flashUntil) {
    currentPattern = dinoPattern;   // switch back to base animation
    flashing = false;
  }

    // If not flashing, always show base dino icon
  if (!flashing) {
    currentPattern = dinoPattern;
  }

  // Draw whatever pattern should currently be lit
  matrix.renderBitmap(currentPattern, 8, 12);

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

      // LED: show UP pattern for 1.5 sec
      currentPattern = upPattern;
      flashUntil = now + 800;
      flashing = true;
    }
  }

  // -----------------------------
  //   JOYSTICK DOWN → DUCK (hold)
  // -----------------------------
  bool duckNow = (xVal > downThreshold);

  if (duckNow && !lastDuck) {
    Keyboard.press(KEY_DOWN_ARROW);

    // LED: show DOWN pattern for 1.2 sec
    currentPattern = downPattern;
    flashUntil = now + 800;
    flashing = true;
  } 
  else if (!duckNow && lastDuck) {
    Keyboard.release(KEY_DOWN_ARROW);
  }
  lastDuck = duckNow;

  // -----------------------------
  //   JOYSTICK BUTTON → RESTART GAME
  //   Only presses UP arrow once per click
  // -----------------------------
  if (swPressed && !lastButtonDino) {
    Keyboard.press(KEY_UP_ARROW);   // restart game
    delay(5);
    Keyboard.release(KEY_UP_ARROW);

    // LED: show UP pattern for 1.5 sec
      currentPattern = resetPattern;
      flashUntil = now + 800;
      flashing = true;
  }
  lastButtonDino = swPressed;

  delay(1);
}

// -----------------------------
// SNAKE MODE FUNCTION
// -----------------------------
void runSnake() {
  int x = analogRead(joyX);
  int y = analogRead(joyY);
  int sw = digitalRead(joySW);
  unsigned long now = millis();

  // ----------------------------------
  // Restore main pattern after flash
  // ----------------------------------
  if (flashing && now >= flashUntil) {
    currentPattern = snakePattern;   // switch back to base animation
    flashing = false;
  }

  // If not flashing, always show base snake icon
  if (!flashing) {
    currentPattern = snakePattern;
  }

  // LED pattern
  matrix.renderBitmap(currentPattern, 8, 12);

  // -------- DEAD ZONE + AXIS PRIORITY --------- //
  const int center = 512;
  const int threshold = 100; // joystick must move ±100 to register

  int xVal = analogRead(joyX) - center;
  int yVal = analogRead(joyY) - center;

  int dir = 0; // 0 = neutral, 1=UP,2=DOWN,3=LEFT,4=RIGHT

  if (abs(xVal) > abs(yVal)) {
    // X axis dominant
    if (xVal < -threshold) dir = 3; // LEFT
    else if (xVal > threshold) dir = 4; // RIGHT
  }
  else {
    // Y axis dominant
    if (yVal < -threshold) dir = 1; // UP
    else if (yVal > threshold) dir = 2; // DOWN
}


 // Send only if changed
  if (dir != 0 && dir != lastDir) {
    // Release previous key first
    Keyboard.releaseAll();

    if (dir == 1) Keyboard.press(KEY_RIGHT_ARROW);
      else if (dir == 2) Keyboard.press(KEY_LEFT_ARROW);
      else if (dir == 3) Keyboard.press(KEY_UP_ARROW);
      else if (dir == 4) Keyboard.press(KEY_DOWN_ARROW);

    // ---- LED FLASH ---- //
    if (dir == 1)      currentPattern = rightPattern;
      else if (dir == 2) currentPattern = leftPattern;
      else if (dir == 3) currentPattern = upPattern;
      else if (dir == 4) currentPattern = downPattern;

    flashing = true;
    flashUntil = millis() + 800; // flash duration (ms)

    lastDir = dir;
  }

  // BUTTON → Restart game
  if (sw == LOW && !lastButtonSnake) {
    Keyboard.press(' '); // trigger restart
    delay(5);
    Keyboard.release(' ');

    // LED: show UP pattern for 1.5 sec
      currentPattern = resetPattern;
      flashUntil = now + 800;
      flashing = true;
  }
  lastButtonSnake = sw;

  delay(1);
}
