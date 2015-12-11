import java.util.ArrayList;

// Utility wrapper around accessing the camera
import ketai.camera.*;

KetaiCamera cam;
boolean echoImage;

// Searching for the target point
Color targetColor;
Vector2D lastPoint; // camera space

// Camera constants
final int FPS = 16;
final float THRESHOLD = 30;
final float FIDELITY = 0.5;
final Vector2D maxRes = new Vector2D(1280, 960);
Vector2D scaledRes = maxRes.scale(FIDELITY);

// Constants for the trial tasks
final String TARGET_ONE   = "TARGET_ONE";
final String TARGET_TWO   = "TARGET_TWO";
final String TARGET_THREE = "TARGET_THREE";
final String TARGET_FOUR  = "TARGET_FOUR";
final String[] TARGETS = {TARGET_ONE, TARGET_TWO, TARGET_THREE, TARGET_FOUR};

final String ACTION_ONE   = "ACTION_ONE";
final String ACTION_TWO   = "ACTION_TWO";
final String[] ACTIONS = {ACTION_ONE, ACTION_TWO};

// Grading and timing code
ArrayList<Trial> trials;
int curTrial = 0;
int numTrials = 4;
boolean hasStarted = false;

// Color palette
Color pureRed = new Color(255, 0, 0);

Color black           = new Color(0, 0.8);
Color blacktrans      = new Color(0, 0.5);
Color blacklightrans  = new Color(0, 0.2);

Color blue            = new Color(0, 64, 133);
Color bluetrans       = new Color(0, 64, 133, 0.5);
Color brightblue      = new Color(26, 136, 255);
Color brightbluetrans = new Color(26, 136, 255, 0.5);


// ----- Processing callbacks -------------------------------------------------

void setup() {
  imageMode(CENTER);
  noStroke();

  // Rotating the screen causes the camera to reset, so let's lock it
  orientation(LANDSCAPE);

  resetSetup();
}

void draw() {
  background(0);

  if (!hasStarted) {
    // TODO(jezimmer): Consider drawing starting message
  }
  else {
    // uses lastPoint to update lastPoint
    lastPoint = findNearestPixel();

    // Either write out the whole image, or just write the quadrants
    if (echoImage) {
      pushMatrix();
      translate(width/2, height/2);
      scale(-1, 1);
      image(cam, 0, 0, width, height);
      popMatrix();
    }
    else {
      Rectangle camRect = new Rectangle(cam.width, cam.height);
      int cursorQuadrant = camRect.getQuadrant(lastPoint.x, lastPoint.y);

      // Quadrants are flipped because we're computing them with respect to
      // the positive y-axis pointing down, and mirrored because we need to
      // mirror the camera:
      // 4 3
      // 1 2
      getColorForQuad(4, cursorQuadrant).drawFill();
      (new Rectangle(0, 0, width/2, height/2)).draw();

      getColorForQuad(3, cursorQuadrant).drawFill();
      (new Rectangle(width/2, 0, width/2, height/2)).draw();

      getColorForQuad(1, cursorQuadrant).drawFill();
      (new Rectangle(0, height/2, width/2, height/2)).draw();

      getColorForQuad(2, cursorQuadrant).drawFill();
      (new Rectangle(width/2, height/2, width/2, height/2)).draw();
    }

    // Compute location of the cursor in screen space
    Vector2D cursorPoint = reflectHorizontal(cameraToScreen(lastPoint), width);
    targetColor.drawFill();
    ellipseMode(CENTER);
    ellipse(cursorPoint.x, cursorPoint.y, 50, 50);
  }
}

/*
 * Required to be able to use the camera. Other than that, I'm not sure how
 * this function works.
 */
void onCameraPreviewEvent() {
  cam.read();
}

void mousePressed() {
  // If the game hasn't started yet, we want to start a countdown timer
  // that will start the first trial's timer.
  if (!hasStarted) {
    // TODO(jezimmer): Implement initial countdown timer.
    hasStarted = true;
  }

  // First touch is always to initialize the camera
  if (cam == null) {
    cam = new KetaiCamera(this, (int) scaledRes.x, (int) scaledRes.y, FPS);
    cam.setCameraID(/* front-facing camera */ 1);
    cam.start();

    return;
  }

  // We want the image to not be displayed when we're trying to actually
  // perform the trials, but it's useful to help orient the sensor
  // initially (so you can be sure you're clicking on the right object).

  if (echoImage) {
    // Pluck color at current tap and turn off image echoing

    Vector2D lastPoint = getPointUnderMouse();
    int cx = (int) lastPoint.x;
    int cy = (int) lastPoint.y;
    int idx = cy*cam.width + cx;
    targetColor = new Color(cam.pixels[idx]);

    echoImage = false;
  }
  else {
    // Turn image echoing back on
    echoImage = true;

    // Note that we don't reset targetColor or lastPoint. For one,
    // lastPoint would continue to be updated elsewhere, but more
    // importantly, we want to be able to debug whether the point is
    // actually on top of a reasonable spot in the image.
  }
}

// ----- helper functions -----------------------------------------------------

void resetTrials() {
  trials = new ArrayList<Trial>();

  for (int i = 0; i < numTrials; i++) {
    String target = TARGETS[((int) random(0, 4))];
    String action = TARGETS[((int) random(0, 2))];
    String expected = target + action;

    trials.add(new Trial(expected));
  }
}
void resetSetup() {
  targetColor = new Color(0);
  lastPoint = new Vector2D();

  curTrial = 0;
  hasStarted = false;
  echoImage = true;

  resetTrials();
}

/*
 * Helper functions for converting between screen-space coordinates (width
 * x height) and camera-space coordinates (cam.width x cam.height)
 */
Vector2D screenToCamera(Vector2D in) {
  return in.scale(cam.width, cam.height).scale(1. / width, 1. / height);
}
Vector2D cameraToScreen(Vector2D in) {
  return in.scale(width, height).scale(1. / cam.width, 1. / cam.height);
}

/*
 * Reflects a point within a rectangle of width `width` across the center
 * of the rectangle.
 *
 * This is useful because the image from the camera needs to be mirrored
 * when it's displayed, so points drawn onto this canvas won't match up
 * with the correct position in the image unless flipped.
 */
Vector2D reflectHorizontal(Vector2D in, float width) {
  return new Vector2D(width - in.x, in.y);
}

/*
 * Use the current mouse location (mouseX, mouseY) to get a point in the
 * camera image.
 *
 * First scales the screen space to the camera space, then flips the point
 * (so the output is in mirrored camera space).
 */
Vector2D getPointUnderMouse() {
  Vector2D screenTap = new Vector2D(mouseX, mouseY);
  Vector2D cameraTap = screenToCamera(reflectHorizontal(screenTap, width));

  cameraTap.x = (int) cameraTap.x;
  cameraTap.y = (int) cameraTap.y;

  return cameraTap;
}

/*
 * Return the PixelGuess that has the smallest distance: the current one or
 * the one created by looking under the pixel (x, y) in the image.
 *
 * This isn't a very nicely factored function. Ideally, we'd separate the
 * min() logic from camera reading logic. But Java doesn't have a
 * (sufficiently succint) way of taking a min over arbitrary members of a
 * class, so why even try.
 */
PixelGuess minDist(int x, int y, PixelGuess in) {
  int idx = y*cam.width + x;

  if (!(0 <= idx && idx < cam.pixels.length)) return in;

  Color curColor = new Color(cam.pixels[idx]);
  float curDist = targetColor.dist(curColor);

  if (curDist < in.dist) {
    return new PixelGuess(x, y, curDist);
  }
  else {
    return in;
  }
}

/*
 * Return a particular shade, depending on whether the currentQuad is in
 * the same quadrant as the cursor.
 */
Color getColorForQuad(int currentQuad, int cursorQuad) {
  if (currentQuad == cursorQuad) {
    return blue;
  }
  else {
    return blacktrans;
  }
}


/*
 * Starting at lastPoint, search in rings outward to find the nearest point
 * in the camera image whose color is within THRESHOLD of the targetColor.
 *
 * Super stateful, but I think it'll be ok.
 */
Vector2D findNearestPixel() {
  // 442 > sqrt(255^2 + 255^2 + 255^2) = max distance
  PixelGuess result = new PixelGuess(0, 0, 442.);

  // Start at the last point, so we can search more quickly and our search
  // is more stable (results in points close to where we think the object
  // was).
  int x0 = (int) lastPoint.x;
  int y0 = (int) lastPoint.y;

  int maxR = max(cam.width, cam.height);

  // I wish there was a cleaner way :'(
  for (int r = 0; r < maxR; r++) {
    int x;
    int y = y0 - r;
    if (0 <= y) {
      for (x = x0 - r; x <= x0 + r; x++) {
        result = minDist(x, y, result);
      }
    }

    x = x0 + r;
    if (x < width) {
      for (y = y0 - r + 1; y < y0 + r - 1; y++) {
        result = minDist(x, y, result);
      }
    }

    y = y0 + r;
    if (y < height) {
      for (x = x0 - r; x <= x0 + r; x++) {
        result = minDist(x, y, result);
      }
    }

    x = x0 - r;
    if (0 <= x) {
      for (y = y0 - r + 1; y < y0 + r - 1; y++) {
        result = minDist(x, y, result);
      }
    }

    if (result.dist < THRESHOLD) break;
  }

  return new Vector2D(result.x, result.y);
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

  Rectangle(int width, int height) {
    this.start = new Vector2D(0, 0);
    this.size = new Vector2D(width, height);
  }

  Rectangle(int startX, int startY, int width, int height) {
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

class PixelGuess {
  public int x;
  public int y;
  public float dist;

  PixelGuess(int x, int y, float dist) {
    this.x = x;
    this.y = y;
    this.dist = dist;
  }
}

class Trial {
  public int startTime;
  public int endTime;

  public String target;
  public String actual;

  Trial(String target) {
    this.target = target;
  }

  void start() {
    this.startTime = millis();
  }
  void stop(String actual) {
    this.endTime = millis();
    this.actual = actual;
  }

  // Returns 1 if there was an error, else 0
  int getError() {
    // TODO(jezimmer): Implement this function accordingly
    return 0;
  }

  int getTime() {
    return this.endTime - this.startTime;
  }
}
