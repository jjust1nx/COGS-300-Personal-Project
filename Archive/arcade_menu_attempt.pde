import processing.serial.*;
import processing.sound.*;
import ddf.minim.*;

Serial myPort;
Minim minim;
AudioPlayer jumpSound, deathSound, scoreSound;
SoundFile pointSound, ggSound;

// -----------------------------
// MENU VARIABLES
// -----------------------------
int currentMode = 1;       // 1 = Dino, 2 = Snake
boolean gameRunning = false;

// -----------------------------
// DINO VARIABLES
// -----------------------------
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
boolean gameOverDino = false;

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

// -----------------------------
// SNAKE VARIABLES
// -----------------------------
int cols = 30;
int rows = 20;
int cellSize = 20;

int lastTurnTime = 0;
int turnCooldown = 150; // ms

ArrayList<PVector> snake;
PVector food;
String dir = "RIGHT";
boolean gameOverSnake = false;
int scoreSnake = 0;

// -----------------------------
// SETUP
// -----------------------------
void settings() { size(600, 400); }

void setup() {
  minim = new Minim(this);
  
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);
  myPort.bufferUntil('\n');
  
  setupDino();
  setupSnake();
}

// -----------------------------
// DRAW LOOP
// -----------------------------
void draw() {
  background(0);
  
  if (!gameRunning) drawMenu();
  else {
    if (currentMode == 1) runDino();
    else if (currentMode == 2) runSnake();
  }
}

// -----------------------------
// MENU FUNCTIONS
// -----------------------------
void drawMenu() {
  textAlign(CENTER, CENTER);
  textSize(32);
  
  fill(currentMode==1 ? color(0,255,0) : 255);
  text("DINO", width/2, height/2 - 40);
  
  fill(currentMode==2 ? color(0,255,0) : 255);
  text("SNAKE", width/2, height/2 + 40);
}

// -----------------------------
// SERIAL INPUT (merged)
// -----------------------------
void serialEvent(Serial p) {
  String input = p.readStringUntil('\n');
  if (input == null) return;
  input = trim(input);
  
  if (!gameRunning) {
    if (input.equals("DINO")) currentMode = 1;
    else if (input.equals("SNAKE")) currentMode = 2;
    else if (input.equals("START")) {
      gameRunning = true;
      if (currentMode==1) resetDinoGame();
      else if (currentMode==2) resetSnakeGame();
    }
  } else {
    if (currentMode == 1) {
        // Dino controls from joystick
        if (input.equals("UP") && onGround) { 
            velocityY = -15; 
            onGround = false; 
            ducking = false; 
            triggerJump();
        }
        if (input.equals("DOWN") && onGround) {
            ducking = true;
        }
        if (input.equals("BTN") && gameOverDino) {
            resetDinoGame();
        }
    } else if (currentMode == 2) {
        serialSnake(p);
    }
}

}

// -----------------------------
// -----------------------------
// DINO GAME FUNCTIONS
// -----------------------------
void setupDino() {
  textAlign(CENTER, CENTER);
  textSize(18);
  
  jumpSound  = minim.loadFile("jump.wav");
  deathSound = minim.loadFile("die.wav");
  scoreSound = minim.loadFile("point.wav");
  
  spawnObstacle();
}

void runDino() {

  // ---------------------------
// Day/Night cycle with proper hold + smooth outlines
// ---------------------------
if (!gameOverDino) {

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
  gameOverDino = true;
}


  // ---------------------------
  // HUD
  // ---------------------------
  fill(whiteFade);
  text("Score: " + score, width - 80, 30);


  if (gameOverDino) {
    textSize(32);
    fill(255, 0, 0);
  text("Game Over", width/2, height/2);

  textSize(18);
  fill(whiteFade);
  text("Press the middle joystick button to play again!", width/2, height/2 + 40);

    
    noLoop();
  }
}

void resetDinoGame() {
  // Reset dino
  dinoY = groundY;
  velocityY = 0;
  onGround = true;
  ducking = false;

  // Reset obstacle
  obstacleX = width + 200;
  speed = 6;
  score = 0;
  gameOverDino = false;
  spawnObstacle(); // spawn first obstacle
  
  // Reset day/night
  lightLevel = 255;
  goingDarker = true;
  
  loop(); // restart draw loop if it was stopped
}

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

void triggerJump(){ jumpSound.rewind(); jumpSound.play();}
void triggerDeath(){ deathSound.rewind(); deathSound.play();}
void triggerPoint(){ scoreSound.rewind(); scoreSound.play(); }

void keyPressed() {
  if (gameOverDino) {
    if (keyCode == UP) { // ' ' for button
    resetDinoGame();
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

// -----------------------------
// SNAKE GAME FUNCTIONS
// -----------------------------
void setupSnake(){
  frameRate(7);
  snake = new ArrayList<PVector>();
  snake.add(new PVector(cols/2, rows/2));
  spawnFood();
  pointSound = new SoundFile(this, "snakecoin.mp3");
  ggSound = new SoundFile(this, "gameover.mp3");
  textAlign(CENTER, CENTER);
}

void runSnake() {
  background(0);

  if (gameOverSnake) {
    drawGameOver();
    return;
  }

  updateSnake();
  drawFood();
  drawSnake();
  drawHUD();
}

void resetSnakeGame() {
  snake.clear();
  snake.add(new PVector(cols/2, rows/2));
  
  pointSound.stop();
  ggSound.stop();

  dir = "RIGHT";
  score = 0;
  gameOverSnake = false;
  spawnFood();
}

void updateSnake() {
  // current head
  int hx = (int) snake.get(0).x;
  int hy = (int) snake.get(0).y;

  // move head
  if (dir.equals("UP"))    hy--;
  if (dir.equals("DOWN"))  hy++;
  if (dir.equals("LEFT"))  hx--;
  if (dir.equals("RIGHT")) hx++;

  // WALL COLLISION
  if (hx < 0 || hx >= cols || hy < 0 || hy >= rows) {
    if (!gameOverSnake) ggSound.play();  // gg SOUND
    gameOverSnake = true;
    return;
  }

  // create the NEW HEAD
  PVector newHead = new PVector(hx, hy);

  // insert new head
  snake.add(0, newHead);

  // SELF COLLISION (skip checking index 0 and 1)
  for (int i = 2; i < snake.size(); i++) {
    PVector s = snake.get(i);
    if (s.x == newHead.x && s.y == newHead.y) {
      if (!gameOverSnake) ggSound.play();  // gg SOUND
      gameOverSnake = true;
      return;
    }
  }

  // FOOD
  if (newHead.equals(food)) {
    score++;
    pointSound.play(); // point SOUND
    spawnFood();
  } else {
    // move tail
    snake.remove(snake.size()-1);
  }
}

// ----------------------
// DRAW OBJECTS
// ----------------------
void drawSnake() {
  fill(0, 255, 0);
  for (PVector p : snake) {
    rect(p.x*cellSize, p.y*cellSize, cellSize, cellSize);
  }
}

void drawFood() {
  fill(255, 0, 0);
  rect(food.x*cellSize, food.y*cellSize, cellSize, cellSize);
}

void drawHUD() {
  fill(255);
  textSize(20);
  text("Score: " + score, width - 80, 20);
}

// ----------------------
// GAME OVER SCREEN
// ----------------------
void drawGameOver() {
  fill(255, 0, 0);
  textSize(40);
  text("GAME OVER", width/2, height/2 - 20);

  fill(255);
  textSize(18);
  text("Press joystick button to restart", width/2, height/2 + 20);
  text("Final Score: " + score, width/2, height/2 + 60);
}

// ----------------------
// FOOD
// ----------------------
void spawnFood() {
  food = new PVector(int(random(cols)), int(random(rows)));
}

// ----------------------
// SERIAL INPUT
// ----------------------
void serialSnake(Serial p) {

  String input = p.readStringUntil('\n');
  if (input == null) return;

  input = input.trim();
  
  // ----------------------------- // Reset the game if BTN received // ----------------------------- 
  if (input.equals("BTN")) { 
    if (gameOverSnake) { 
    resetSnakeGame(); 
    return; 
    } 
  } // skip other input if game is over 
  
  if (gameOverSnake) return;

  // --- Cooldown prevents rapid direction spam ---
  if (millis() - lastTurnTime < turnCooldown) return;

  boolean turned = false;

  if (input.equals("UP") && !dir.equals("DOWN")) {
    dir = "UP"; turned = true;
  }
  if (input.equals("DOWN") && !dir.equals("UP")) {
    dir = "DOWN"; turned = true;
  }
  if (input.equals("LEFT") && !dir.equals("RIGHT")) {
    dir = "LEFT"; turned = true;
  }
  if (input.equals("RIGHT") && !dir.equals("LEFT")) {
    dir = "RIGHT"; turned = true;
  }

  if (turned) {
    lastTurnTime = millis();
  }
}
