// -----------------------------------------------------
// DINO RUNNER DELUXE — Arduino-Ready Version
// Features:
//
// ✔ Multiple obstacle types
// ✔ Bird with flapping animation
// ✔ Day/Night cycle
// ✔ Speed increases gradually
// ✔ Duck + Jump working perfectly
// ✔ Debug mode (press 'D')
// -----------------------------------------------------

import processing.sound.*;
import ddf.minim.*;
import processing.serial.*;
Serial myPort;

//SoundFile jumpSound;
//SoundFile deathSound;
//SoundFile scoreSound;

Minim minim;
AudioPlayer jumpSound, deathSound, scoreSound;

// Dino settings
float dinoX = 80;
float dinoY = 300;
float dinoSize = 40;
float groundY = 300;
float birdHeightAboveGround = 20;

float velocityY = 0;
float gravity = 1.0;
boolean onGround = true;
boolean ducking = false;

// Obstacle
float obstacleX = 600;
float obstacleY;
float obstacleWidth;
float obstacleHeight;
int obstacleType = 0; // 0=small cactus, 1=big cactus, 2=bird

int wingFrame = 0;      // bird animation
int wingTimer = 0;

int lastBlinkScore = 0;
boolean blinkQueued = false;

// Game variables
float speed = 6;
int score = 0;
boolean gameOver = false;

// Day/Night cycle
float lightLevel = 255;     // 0 = black (night), 255 = white (day)
float lightSpeed = 0.25;     // increase for faster cycling
boolean goingDarker = true; // direction of cycle

// Day/Night timing improvements
int holdTimer = 0;
int holdDuration = 300;   // how long to HOLD day/night (frames)
float whiteFade = 0;      // 0 = black outlines, 255 = white outlines

// Debug mode
boolean debug = false;

float volume = 1; // 0.0 to 1.0
float gain = map(volume, 0, 1, -40, 0);

void triggerJump() {
  float gain = map(volume, 0, 1, -40, 0);
  jumpSound.setGain(gain);
  jumpSound.rewind(); // set volume 0.0–1.0
  jumpSound.play();
}

void triggerDeath() {
  float gain = map(volume, 0, 1, -40, 0);
  deathSound.setGain(gain);
  deathSound.rewind();
  deathSound.play();
}

void triggerPoint() {
  float gain = map(volume, 0, 1, -40, 0);
  scoreSound.setGain(gain);
  scoreSound.rewind();
  scoreSound.play();
}

void setup() {
  size(600, 400);
  
  minim = new Minim(this);
  
  myPort = new Serial(this, Serial.list()[0], 9600);
  textAlign(CENTER, CENTER);
  textSize(18);
  spawnObstacle();
  
  jumpSound  = minim.loadFile("jump.wav");
  deathSound = minim.loadFile("die.wav");
  scoreSound = minim.loadFile("point.wav");
  
  //jumpSound = new SoundFile(this, "jump.wav");
  //deathSound = new SoundFile(this, "die.wav");
  //scoreSound = new SoundFile(this, "point.wav");
}

void resetGame() {
  // Reset dino
  dinoY = groundY;
  velocityY = 0;
  onGround = true;
  ducking = false;

  // Reset obstacle
  obstacleX = width + 200;
  speed = 6;
  score = 0;
  gameOver = false;
  spawnObstacle(); // spawn first obstacle
  
  // Reset day/night
  lightLevel = 255;
  goingDarker = true;
  
  loop(); // restart draw loop if it was stopped
}


void draw() {
  updateVolume();
  
  // ---------------------------
// Day/Night cycle with proper hold + smooth outlines
// ---------------------------
if (!gameOver) {

  // Check if we are holding at full day/night
  boolean holding = false;

  if (lightLevel >= 255) {        // full day
    lightLevel = 255;
    holding = true;
    holdTimer++;
    if (holdTimer >= holdDuration) {
      holdTimer = 0;
      goingDarker = true;         // start night
      holding = false;
    }
  } 
  else if (lightLevel <= 0) {    // full night
    lightLevel = 0;
    holding = true;
    holdTimer++;
    if (holdTimer >= holdDuration) {
      holdTimer = 0;
      goingDarker = false;        // start day
      holding = false;
    }
  }

  // Only transition if not holding
  if (!holding) {
    if (goingDarker) lightLevel -= lightSpeed;
    else             lightLevel += lightSpeed;
  }

  // Smooth outline/text color transition
  float targetWhite = (lightLevel < 120) ? 255 : 0; // fade to white in night
  whiteFade = lerp(whiteFade, targetWhite, 0.03);

  // Draw background
  background(lightLevel);

  // Ground line
  stroke(whiteFade);
  line(0, groundY + dinoSize/2, width, groundY + dinoSize/2);
}

  // ---------------------------
  // Draw Dinosaur
  // ---------------------------
  if (ducking && onGround) {
    fill(50, 150, 50);
    rect(dinoX, groundY + 10, dinoSize, dinoSize/2);
  } else {
    fill(50, 200, 50);
    rect(dinoX, dinoY, dinoSize, dinoSize);
  }

  // ---------------------------
  // Jump physics
  // ---------------------------
  if (!onGround) {
    velocityY += gravity;
    dinoY += velocityY;

    if (dinoY >= groundY) {
      dinoY = groundY;
      velocityY = 0;
      onGround = true;
    }
  }

  // ---------------------------
  // Obstacle movement
  // ---------------------------
  obstacleX -= speed;

  if (obstacleX < -obstacleWidth) {
    spawnObstacle();
    speed += 0.15;         // speed curve
    score++;
    
    if (score % 5 == 0)
        triggerPoint(); // Score sound
    }

  // ---------------------------
  // Draw obstacle
  // ---------------------------
  drawObstacle();

  // ---------------------------
  // Collision detection
  // ---------------------------
 // ---------------------------
// Collision detection
// ---------------------------
float dinoHitX = dinoX;
float dinoHitWidth = dinoSize;

float dinoHitY;
float dinoHitHeight;

if (ducking && onGround) {
  dinoHitY = groundY + 10;         // matches drawn rectangle when ducking
  dinoHitHeight = dinoSize / 2;    // half-height
} else {
  dinoHitY = dinoY;
  dinoHitHeight = dinoSize;
}

boolean xHit = (dinoHitX + dinoHitWidth > obstacleX) && (dinoHitX < obstacleX + obstacleWidth);
boolean yHit = (dinoHitY + dinoHitHeight > obstacleY) && (dinoHitY < obstacleY + obstacleHeight);

if (xHit && yHit) {
  triggerDeath(); // Death sound
  gameOver = true;
}


  // ---------------------------
  // HUD
  // ---------------------------
  fill(whiteFade);
  text("Score: " + score, width - 80, 30);


  if (gameOver) {
    textSize(32);
    fill(255, 0, 0);
  text("Game Over", width/2, height/2);

  textSize(18);
  fill(whiteFade);
  text("Press the middle joystick button to play again!", width/2, height/2 + 40);

    
    noLoop();
  }

  // ---------------------------
  // Debug mode
  // ---------------------------
  if (debug) drawDebug();
}

void updateVolume() {
  while (myPort.available() > 0) {
    String val = myPort.readStringUntil('\n'); // Read until newline
    if (val != null) {
      val = trim(val);                        // Remove whitespace
      int potVal = int(val);                   // Convert to integer
      volume = constrain(map(potVal, 0, 1023, 0, 1), 0, 1); // Map to 0–1
       println("Pot: " + potVal + "  Volume: " + volume);
    }
  }
}

 
// -----------------------------------------------------
// SPAWN RANDOM OBSTACLE
// -----------------------------------------------------
void spawnObstacle() {
  obstacleX = width + random(200, 400);

  obstacleType = int(random(3)); // 0=small cactus, 1=big cactus, 2=bird

  if (obstacleType == 0) {  
    // Small cactus
    obstacleWidth = 20;
    obstacleHeight = 40;
    obstacleY = groundY - obstacleHeight + dinoSize/2;

  } else if (obstacleType == 1) {
    // Big cactus
    obstacleWidth = 30;
    obstacleHeight = 58; // 60 height = hardest
    obstacleY = groundY - obstacleHeight + dinoSize/2;

  } else {
    // Bird (requires ducking)
    obstacleWidth = 50;
    obstacleHeight = 30;

    // Correct flying height (just above dino head)
    obstacleY = groundY - birdHeightAboveGround - obstacleHeight + 22;
  }
}

// -----------------------------------------------------
// DRAW OBSTACLE
// -----------------------------------------------------
void drawObstacle() {
  fill(200, 50, 50);

  if (obstacleType <= 1) {
    // Cactus
    rect(obstacleX, obstacleY, obstacleWidth, obstacleHeight);

  } else {
    // Bird with flapping wings
    wingTimer++;
    if (wingTimer > 8) {
      wingFrame = 1 - wingFrame;
      wingTimer = 0;
    }
    
    // Draw lower bird
    rect(obstacleX, obstacleY, obstacleWidth, obstacleHeight);

    // Wings
    if (wingFrame == 0) {
      rect(obstacleX + 10, obstacleY - 10, 20, 8); // wings up
    } else {
      rect(obstacleX + 10, obstacleY + obstacleHeight, 20, 8); // wings down
    }
    
    // Draw a second bird stacked above
    float birdGap = 30;  // vertical spacing between birds
    float upperY = obstacleY - birdGap - obstacleHeight;

    rect(obstacleX, upperY, obstacleWidth, obstacleHeight);

    if (wingFrame == 0) {
      rect(obstacleX + 10, upperY - 10, 20, 8);
    } else {
      rect(obstacleX + 10, upperY + obstacleHeight, 20, 8);
    }
  }
}

// -----------------------------------------------------
// KEYBOARD INPUT (for PC + Arduino keyboard emulation)
// -----------------------------------------------------
void keyPressed() {
  if (gameOver) {
    if (keyCode == UP) { // ' ' for button
    resetGame();
    }
    return; // skip other controls while restarting
  }

  // Normal controls
  if (key == ' ' && onGround) { // jump
    velocityY = -15;
    onGround = false;
    ducking = false;
    triggerJump();
  }
  
  if (keyCode == DOWN && onGround) { // duck
    ducking = true;
  }
  
  if (key == 'd' || key == 'D') { // debug toggle
    debug = !debug;
  }
}


void keyReleased() {
  if (keyCode == DOWN) ducking = false;
}

// -----------------------------------------------------
// DEBUG MODE
// -----------------------------------------------------
void drawDebug() {
  fill(0);
  text("DEBUG", 40, 20);

  // Dino hitbox
  noFill();
  stroke(0, 0, 255);
  rect(dinoX, dinoY, dinoSize, dinoSize);

  // Obstacle hitbox
  stroke(255, 0, 0);
  rect(obstacleX, obstacleY, obstacleWidth, obstacleHeight);
}
