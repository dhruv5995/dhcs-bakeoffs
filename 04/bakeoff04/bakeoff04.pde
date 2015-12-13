import java.util.ArrayList;

// Utility wrapper around accessing the sensors
import ketai.sensors.*;
KetaiSensor sensor;
float z0;

// Vibration
import android.content.Context;
import android.os.Vibrator;
final int vibeDuration = 18;
Vibrator vibe;

// Camera constants
final int FPS = 16;
final float THRESHOLD = 30;
final float FIDELITY = 0.5;
final Vector2D maxRes = new Vector2D(1280, 960);
Vector2D scaledRes = maxRes.scale(FIDELITY);

// Constants for the trial tasks
final String ACTION_CW  = "ACTION_CW";
final String ACTION_CCW = "ACTION_CCW";
final String[] ACTIONS  = {ACTION_CW, ACTION_CCW};

// Grading and timing code
ArrayList<Trial> trials;
int curTrial = 0;
int numTrials = 4;
boolean hasStarted = false;

// Proximity sensing and target selection
int selectedTarget;
boolean isClose;
int fromTime;
final int cycleSpeed = 800;

// Store the currently selected action
String selectedAction;

// Color palette
Color pureRed = new Color(255, 0, 0);

Color black = new Color(0, 0.8);
Color gray  = new Color(48, 48, 48);
Color white = new Color(240, 240, 240);

Color blue            = new Color(0, 64, 133);
Color bluetrans       = new Color(0, 64, 133, 0.5);
Color brightblue      = new Color(26, 136, 255);
Color brightbluetrans = new Color(26, 136, 255, 0.5);


// ----- Processing callbacks -------------------------------------------------

void setup() {
  imageMode(CENTER);
  noStroke();

  // Vibration
  vibe = (Vibrator) getActivity().getSystemService(Context.VIBRATOR_SERVICE);

  sensor = new KetaiSensor(this);
  sensor.start();

  orientation(PORTRAIT);

  textFont(createFont("Arial", 36));

  resetSetup();
}

void draw() {
  background(0);

  if (!hasStarted) {
    String message = "Your first of " + numTrials
      + " trials starts once you tap.\n"
      + "\n";

    textAlign(CENTER, CENTER);
    white.drawFill();
    text(message, width/2, height/2);
  }
  else if (curTrial < numTrials) {

    // Draw targets
    int curTarget = getCurrentTarget();

    pushMatrix();
    translate(width/2, height/2);

    int tw = 100;
    Vector2D targetSize = new Vector2D(tw, tw);

    Vector2D borderWidth = new Vector2D(20, 20);

    Vector2D targetStart;
    Rectangle rectTarget;

    for (int i = 0; i < 4; i++) {
      targetStart = new Vector2D(-tw/2, (-3.5 + 2*i) * tw);
      rectTarget = new Rectangle(targetStart, targetSize);

      // Draw outline around the target for the current trial
      int targetTarget = trials.get(curTrial).targetTarget;
      if (i == targetTarget) {
        white.drawFill();
        Vector2D borderStart = targetStart.sub(borderWidth);
        Vector2D borderSize = targetSize.add(borderWidth.scale(2));
        (new Rectangle(borderStart, borderSize)).draw();
      }

      if (i == curTarget) {
        brightblue.drawFill();
      }
      else {
        gray.drawFill();
      }

      rectTarget.draw();
    }
    popMatrix();

    // Draw actions
    float r = 80; // TODO(jezimmer): rename these
    float R = 200;
    String targetAction = trials.get(curTrial).targetAction;

    white.drawFill();
    if (targetAction.equals(ACTION_CCW)) {
      ellipse(R/2, height/2, r, r);
    }
    else if (targetAction.equals(ACTION_CW)) {
      ellipse(width - R/2, height/2, r, r);
    }

    Rectangle curActionDisplay = new Rectangle(0,0,0,0);
    if (selectedAction.equals(ACTION_CCW)) {
      curActionDisplay = new Rectangle(0, 0, R, height);
    }
    else if (selectedAction.equals(ACTION_CW)) {
      curActionDisplay = new Rectangle(width - R, 0, R, height);
    }

    brightbluetrans.drawFill();
    curActionDisplay.draw();
  }
  else {
    String message = getResults();

    textAlign(CENTER, CENTER);
    white.drawFill();
    text(message, width/2, height/2);
  }
}

void onLightEvent(float d) {
  float epsilon = 5;

  if (isClose && d > epsilon) {
    // Save the current target
    selectedTarget = getCurrentTarget();

    //fromTime = (millis() - fromTime) % (4 * cycleSpeed);

    // Hand retreated from sensor
    isClose = false;
  }
  else if (!isClose && d < epsilon) {
    // Hand approached sensor

    isClose = true;

    // We're about to start the targets moving again, so let's set the fromTime
    // so that there's no "jump" in which target is selected.
    fromTime = cycleSpeed * selectedTarget;
  }

  performNext();
}

void onAccelerometerEvent(float x, float y, float z) {
  float tiltThreshold = 2.;
  if (x < -tiltThreshold) {
    selectedAction = ACTION_CW;
  }
  else if (x > tiltThreshold) {
    selectedAction = ACTION_CCW;
  }
  else {
    selectedAction = "";
  }

  performNext();
}

void mousePressed() {
  if (!hasStarted) {
    hasStarted = true;
    fromTime = millis();
  }
}

// ----- helper functions -----------------------------------------------------

void resetTrials() {
  trials = new ArrayList<Trial>();

  for (int i = 0; i < numTrials; i++) {
    int target = (int) random(0, 4);
    String action = ACTIONS[(int) random(0, 2)];

    trials.add(new Trial(target, action));
  }
}

void resetSetup() {
  curTrial = 0;
  hasStarted = false;

  selectedTarget = 0;
  selectedAction = "";
  isClose = false;
  fromTime = millis();

  resetTrials();
}

/*
 * We want to return the pre-selected target if the hand is far away.
 *
 * Otherwise, use the difference between the current time and the fromTime
 * (i.e., the time when the targets started moving), get the current target to
 * highlight.
 */
int getCurrentTarget() {
  if (isClose) {
    return ((millis() - fromTime) / cycleSpeed) % 4;
  }
  else {
    return selectedTarget;
  }
}

/*
 * Stop the current trial, and advance to the next one (providing either of
 * these things are legal).
 */
void performNext() {
  if (curTrial < numTrials) {
    if (trials.get(curTrial).isCorrect(selectedTarget, selectedAction)) {
      // correct!
      vibe.vibrate(vibeDuration);

      if (curTrial < numTrials) {
        trials.get(curTrial).stop(selectedTarget, selectedAction);
        curTrial++;
      }

      if (curTrial < numTrials) {
        trials.get(curTrial).start();
      }
    }
  }
}

int sumErrors() {
  int result = 0;
  for (Trial t : trials) {
    result += t.getError();
  }
  return result;
}

int sumTimes() {
  int result = 0;
  for (Trial t : trials) {
    result += t.getTime();
  }
  return result;
}

/*
 *
 */
String getResults() {
  String result = "";
  float timeSeconds = sumTimes() / 1000.;
  result += "Done!\n"
    + "Errors: " + sumErrors() + "\n"
    + "Time: " + timeSeconds + "s\n"
    + "Average: " + (timeSeconds / numTrials) + "s per trial\n";
  return result;
}


// ----- classes --------------------------------------------------------------

class Color {
  public float r;
  public float g;
  public float b;
  public float a;
  private boolean hsb;

  Color(float gray) {
    this.r = gray;
    this.g = gray;
    this.b = gray;
    this.a = 1.f;
    this.hsb = false;
  }

  Color(float r, float g, float b) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = 1.f;
    this.hsb = false;
  }

  Color(float gray, float a) {
    this.r = gray;
    this.g = gray;
    this.b = gray;
    this.a = a;
    this.hsb = false;
  }


  Color(float r, float g, float b, float a) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;
    this.hsb = false;
  }

  Color(float r, float g, float b, boolean hsb) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = 1.f;
    this.hsb = hsb;
  }

  Color(float r, float g, float b, float a, boolean hsb) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;
    this.hsb = hsb;
  }

  Color(int rgba) {
    this.r = red(rgba);
    this.g = green(rgba);
    this.b = blue(rgba);
    this.a = alpha(rgba);
    this.hsb = false;
  }

  Color(int rgba, boolean hsb) {
    this.hsb = hsb;
    this.a = alpha(rgba);

    if (hsb) {
      this.r = hue(rgba);
      this.g = saturation(rgba);
      this.b = brightness(rgba);
    }
    else {
      this.r = red(rgba);
      this.g = green(rgba);
      this.b = blue(rgba);
    }
  }

  void drawColorMode() {
    if (this.hsb) {
      colorMode(HSB, 360, 100, 100, 1);
    }
    else {
      colorMode(RGB, 255, 255, 255, 1);
    }
  }

  void drawFill() {
    drawColorMode();
    fill(r, g, b, a);
  }

  void drawStroke() {
    drawColorMode();
    stroke(r, g, b, a);
  }

  // Compute approximate color distance, as outlined in this writeup:
  // http://www.compuphase.com/cmetric.htm
  float dist(Color that) {
    float rmean = (this.r + that.r) / 2;

    float dr = this.r - that.r;
    float dg = this.g - that.g;
    float db = this.b - that.b;

    float d2 = ((int) ((512 + rmean) * dr*dr) >> 8)
        + (4 * dg*dg)
        + ((int) ((767 - rmean) * db*db) >> 8);

    return sqrt(d2);
  }

  String toString() {
    String result = "";
    if (hsb) {
      result += "hsla(";
    }
    else {
      result += "rgba(";
    }
    result += r + ", " + g + ", " + b + ", " + a + ")";

    return result;
  }
}

class Vector2D {
  public float x;
  public float y;

  Vector2D() {
    this.x = 0;
    this.y = 0;
  }

  Vector2D(Vector2D that) {
    this.x = that.x;
    this.y = that.y;
  }

  Vector2D(float x, float y) {
    this.x = x;
    this.y = y;
  }

  boolean equals(Vector2D that) {
    return abs(this.x - that.x) < 1e-6 && abs(this.y - that.y) < 1e-6;
  }

  public Vector2D add(Vector2D that) {
    return new Vector2D(this.x + that.x, this.y + that.y);
  }
  public Vector2D sub(Vector2D that) {
    return new Vector2D(this.x - that.x, this.y - that.y);
  }
  public Vector2D scale(float c) {
    return new Vector2D(c * this.x, c * this.y);
  }
  public Vector2D scale(float cx, float cy) {
    return new Vector2D(cx * this.x, cy * this.y);
  }
}

class Rectangle {
  public Vector2D start;
  public Vector2D size;

  Rectangle(float width, float height) {
    this.start = new Vector2D(0, 0);
    this.size = new Vector2D(width, height);
  }

  Rectangle(float startX, float startY, float width, float height) {
    this.start = new Vector2D(startX, startY);
    this.size = new Vector2D(width, height);
  }

  Rectangle(Vector2D start, Vector2D size) {
    this.start = start;
    this.size  = size;
  }

  Vector2D getCenter() {
    return size.scale(0.5).add(start);
  }

  Vector2D getEnd() {
    return start.add(size);
  }

  boolean contains(float x, float y) {
    return (start.x <= x && x <= start.x + size.x) &&
           (start.y <= y && y <= start.y + size.y);
  }

  // The quadrants here obey the same properties as those in the Cartesian
  // space with respect to signs. However, being rectangles, the positive y
  // direction is down, so the quadrants are flipped vertically.
  //
  // 3 4  (instead of)  2 1
  // 2 1                3 4
  int getQuadrant(float x, float y) {
    Vector2D c = getCenter();

    if (x >= c.x && y >= c.y) {
      return 1;
    }
    else if (x < c.x && y >= c.y) {
      return 2;
    }
    else if (x < c.x && y < c.y) {
      return 3;
    }
    else {
      return 4;
    }
  }

  void draw() {
    rectMode(CORNER);
    rect(start.x, start.y, size.x, size.y);
  }
}

class Trial {
  public int startTime;
  public int endTime;

  public int targetTarget;
  public int actualTarget;
  public String targetAction;
  public String actualAction;

  Trial(int targetTarget, String targetAction) {
    this.targetTarget = targetTarget;
    this.targetAction = targetAction;
  }

  void start() {
    this.startTime = millis();
  }
  void stop(int actualTarget, String actualAction) {
    this.endTime = millis();
    this.actualTarget = actualTarget;
    this.actualAction = actualAction;
  }

  boolean isCorrect(int target, String action) {
    System.out.println(target + " : " + targetTarget);
    System.out.println(action + " : " + targetAction);
    return target == targetTarget && action.equals(targetAction);
  }

  // Returns 1 if there was an error, else 0
  int getError() {
    if (isCorrect(actualTarget, actualAction)) {
      return 0;
    }
    else {
      return 1;
    }
  }

  int getTime() {
    return this.endTime - this.startTime;
  }
}
