import processing.serial.*;

Serial myPort;
int cols = 20;
int rows = 20;
int cellSize = 20;

ArrayList<PVector> snake;
PVector food;
String dir = "RIGHT";

// Settings function for variable window size
void settings() {
  size(cols * cellSize, rows * cellSize);  // Works now
}

void setup() {
  frameRate(10); // Snake speed

  // Initialize snake
  snake = new ArrayList<PVector>();
  snake.add(new PVector(cols/2, rows/2));

  spawnFood();

  // Open Serial port
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);
  myPort.bufferUntil('\n');
}

void draw() {
  background(0);

  // Move snake
  PVector head = snake.get(0).copy();
  if (dir.equals("UP")) head.y--;
  if (dir.equals("DOWN")) head.y++;
  if (dir.equals("LEFT")) head.x--;
  if (dir.equals("RIGHT")) head.x++;

  // Wrap around edges
  head.x = (head.x + cols) % cols;
  head.y = (head.y + rows) % rows;

  // Check collision with self
  for (PVector p : snake) {
    if (p.equals(head)) {
      noLoop(); // Game over
      println("Game Over!");
    }
  }

  snake.add(0, head);

  // Check food
  if (head.equals(food)) {
    spawnFood();
  } else {
    snake.remove(snake.size()-1);
  }

  // Draw food
  fill(255,0,0);
  rect(food.x*cellSize, food.y*cellSize, cellSize, cellSize);

  // Draw snake
  fill(0,255,0);
  for (PVector p : snake) {
    rect(p.x*cellSize, p.y*cellSize, cellSize, cellSize);
  }
}

void spawnFood() {
  food = new PVector(int(random(cols)), int(random(rows)));
}

void serialEvent(Serial p) {
  String input = p.readStringUntil('\n');
  if (input != null) {
    input = input.trim();
    // Prevent reversing direction
    if ((input.equals("UP") && !dir.equals("DOWN")) ||
        (input.equals("DOWN") && !dir.equals("UP")) ||
        (input.equals("LEFT") && !dir.equals("RIGHT")) ||
        (input.equals("RIGHT") && !dir.equals("LEFT"))) {
      dir = input;
    }
  }
}
