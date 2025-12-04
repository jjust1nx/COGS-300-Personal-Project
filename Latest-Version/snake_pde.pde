import processing.serial.*;
import processing.sound.*;

SoundFile pointSound;
SoundFile ggSound;

int cols = 30;
int rows = 20;
int cellSize = 20;

int lastTurnTime = 0;
//int turnCooldown = 100; // ms

boolean turnedThisFrame = false;

ArrayList<PVector> snake;
PVector food;
String dir = "RIGHT";
String nextDir = "RIGHT";
boolean gameOver = false;
int score = 0;

// --------------------
// WINDOW SIZE
// --------------------
void settings() {
  size(600, 400); 
}

void setup() {
  frameRate(8);  // slower snake

  snake = new ArrayList<PVector>();
  snake.add(new PVector(cols/2, rows/2));

  spawnFood();
  
  pointSound = new SoundFile(this, "snakecoin.mp3");
  ggSound = new SoundFile(this, "gameover.mp3");

  textAlign(CENTER, CENTER);
}

void draw() {
  background(0);

  if (gameOver) {
    drawGameOver();
    return;
  }

  //turnedThisFrame = false; // reset turn flag at the start of each frame
  updateSnake();
  drawFood();
  drawSnake();
  drawHUD();
}

// ----------------------
// SNAKE MOVEMENT
// ----------------------
void updateSnake() {
  
  dir = nextDir;
  
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
    if (!gameOver) ggSound.play();  // gg SOUND
    gameOver = true;
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
      if (!gameOver) ggSound.play();  // gg SOUND
      gameOver = true;
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
// RESET GAME
// ----------------------
void resetGame() {
  snake.clear();
  snake.add(new PVector(cols/2, rows/2));
  
  pointSound.stop();
  ggSound.stop();

  dir = "RIGHT";
  nextDir = "RIGHT";
  score = 0;
  gameOver = false;
  spawnFood();
}

// ----------------------
// FOOD
// ----------------------
void spawnFood() {
  food = new PVector(int(random(cols)), int(random(rows)));
}

void keyPressed() {
  if (gameOver && key == ' ') {
    resetGame();
    return;
  }
  
   if (!gameOver) {
    if (keyCode == UP && !dir.equals("DOWN")) nextDir = "UP";
    if (keyCode == DOWN && !dir.equals("UP")) nextDir = "DOWN";
    if (keyCode == LEFT && !dir.equals("RIGHT")) nextDir = "LEFT";
    if (keyCode == RIGHT && !dir.equals("LEFT")) nextDir = "RIGHT";
  }
  
// Only allow turns if game is running
  /* if (!gameOver) {
    // Check cooldown
    if (millis() - lastTurnTime < turnCooldown) return;

    // UP
    if (keyCode == UP && !dir.equals("DOWN")) {
      dir = "UP";
      lastTurnTime = millis();
    }
    // DOWN
    if (keyCode == DOWN && !dir.equals("UP")) {
      dir = "DOWN";
      lastTurnTime = millis();
    }
    // LEFT
    if (keyCode == LEFT && !dir.equals("RIGHT")) {
      dir = "LEFT";
      lastTurnTime = millis();
    }
    // RIGHT
    if (keyCode == RIGHT && !dir.equals("LEFT")) {
      dir = "RIGHT";
      lastTurnTime = millis();
    }
  } */
}
