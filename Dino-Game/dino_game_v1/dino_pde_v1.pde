// Simple Dinosaur No-Internet Game Clone for Testing
// Controls: SPACE = Jump, DOWN = Duck
// Ready for Arduino integration later (via Serial input)

float dinoX = 80;      // Dino horizontal position
float dinoY = 300;     // Dino vertical position
float groundY = 300;
float dinoSize = 40;

float velocityY = 0;
float gravity = 1.0;
boolean onGround = true;
boolean ducking = false;

float obstacleX = 600;
float obstacleWidth = 20;
float obstacleHeight = 40;
float speed = 6;

int score = 0;
boolean gameOver = false;

void setup() {
  size(600, 400);
  textAlign(CENTER, CENTER);
  textSize(18);
}

void draw() {
  background(240);

  // Ground line
  stroke(0);
  line(0, groundY + dinoSize/2, width, groundY + dinoSize/2);

  // Draw dinosaur
  if (ducking && onGround) {
    fill(50, 150, 50);
    rect(dinoX, groundY + 10, dinoSize, dinoSize/2); // duck pose
  } else {
    fill(50, 200, 50);
    rect(dinoX, dinoY, dinoSize, dinoSize); // normal pose
  }

  // Jump physics
  if (!onGround) {
    velocityY += gravity;
    dinoY += velocityY;
    if (dinoY >= groundY) {
      dinoY = groundY;
      velocityY = 0;
      onGround = true;
    }
  }

  // Move obstacle
  obstacleX -= speed;
  if (obstacleX < -obstacleWidth) {
    obstacleX = width + random(200, 400);

  // 50% chance of tall ground obstacle, 50% small flying obstacle
  if (random(1) < 0.5) {
    obstacleHeight = random(30, 50); // ground obstacle
  } else {
    obstacleHeight = -random(20, 40); // flying obstacle (negative = above ground)
  }

  speed += 0.2;
  score++;
}

// Draw obstacle
fill(200, 50, 50);

float obsY;

// Ground obstacle (positive height)
if (obstacleHeight > 0) {
  obsY = groundY + (dinoSize/2 - obstacleHeight);
}

// Flying obstacle (negative height)
else {
  float h = abs(obstacleHeight);
  obsY = groundY - dinoSize - h - 20; // 20px above dino's head
  obstacleHeight = -h; // ensure drawing uses positive height
}

rect(obstacleX, obsY, obstacleWidth, abs(obstacleHeight));


  // Collision detection
  if (dinoX + dinoSize > obstacleX && dinoX < obstacleX + obstacleWidth) {
    if (dinoY + dinoSize > groundY + (dinoSize/2 - obstacleHeight)) {
      gameOver = true;
    }
  }

  // HUD
  fill(0);
  text("Score: " + score, width - 80, 30);

  if (gameOver) {
    textSize(32);
    fill(255, 0, 0);
    text("Game Over", width/2, height/2);
    noLoop();
  }
}

void keyPressed() {
  if (key == ' ' && onGround) { // Jump
    velocityY = -15;
    onGround = false;
    ducking = false;
  }
  if (keyCode == DOWN && onGround) { // Duck
    ducking = true;
  }
}

void keyReleased() {
  if (keyCode == DOWN) {
    ducking = false;
  }
}
