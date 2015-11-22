import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;

// Vibration
import android.content.Context;
import android.os.Vibrator;

ArrayList<Trial> trials;
HashMap<String, Control> controls = new HashMap<String, Control>();

// Have some padding from the sides
final int border = 10;
// Thickness of sliders and buttons
final int thickness = i2p(0.5f);
// Radius of alignment centers
final int dotRadius = i2p(0.03f);
final int DPI = 445;
final Vector2D vpSize = new Vector2D(i2p(2), i2p(3.5));
Rectangle vp;

// Drags
String curAction;
Vector2D dragStart;
Vector2D dragEnd;

// Grading and timing code
boolean hasStarted = false;
int curTrial = 0;
int numTrials = 4;
int deltaTrials = 0;
CRectangle target;

// Vibration
final int vibeDuration = 18;
Vibrator vibe;
boolean hasCenterCorrect;
boolean hasThetaCorrect;
boolean hasDiamCorrect;

// Color palette
Color transparent     = new Color(0, 0);

Color white           = new Color(238);
Color whitetrans      = new Color(238, 0.5);

Color darkgray        = new Color(32);

Color black           = new Color(0, 0.8);
Color blacktrans      = new Color(0, 0.5);
Color blacklightrans  = new Color(0, 0.2);

Color red             = new Color(166, 43, 12);

Color blue            = new Color(0, 64, 133);
Color bluetrans       = new Color(0, 64, 133, 0.5);
Color brightblue      = new Color(26, 136, 255);
Color brightbluetrans = new Color(26, 136, 255, 0.5);

Color green           = new Color(68, 163, 0);
Color greentrans      = new Color(68, 163, 0, 0.5);


// ----- Processing callbacks -------------------------------------------------

void setup() {
  // Vibration
  vibe = (Vibrator) getActivity().getSystemService(Context.VIBRATOR_SERVICE);

  orientation(PORTRAIT);
  textFont(createFont("Arial", 36));
  noStroke();

  Vector2D vpStart = new Vector2D((width  / 2) - (vpSize.x / 2),
                                  (height / 2) - (vpSize.y / 2));
  vp = new Rectangle(vpStart, vpSize);

  target = new CRectangle();
  target.c.x = vp.getCenter().x;
  target.c.y = vp.getCenter().y;
  target.d   = 150.f;

  // "restart" does some of the things we need to do at the very start as well
  resetSetup();

  // Build up controls
  controls.put("CENTER_DRAG",
      new Control("CENTER_DRAG", transparent, transparent,
        new Rectangle(
          vp.start,
          vp.size.sub(new Vector2D(thickness, thickness)))));

  controls.put("NEXT",
      new Control("NEXT", black, white,
        new Rectangle(
          new Vector2D(vp.getRightX() - thickness, vp.start.y),
          new Vector2D(thickness, thickness))));

  controls.put("DIAM_DRAG",
      new Control("DIAM_DRAG", blacktrans, white,
        new Rectangle(
          new Vector2D(vp.getRightX() - thickness, vp.start.y + thickness),
          new Vector2D(thickness, vp.size.y - 2*thickness))));

  controls.put("THETA_DRAG",
      new Control("THETA_DRAG", blacktrans, white,
        new Rectangle(
          new Vector2D(vp.start.x, vp.getBottomY() - thickness),
          new Vector2D(vp.size.x, thickness))));
}

void draw() {
  background(0);
  noStroke();

  if (!hasStarted) {
    String message = "Your first of " + (numTrials + deltaTrials)
      + " trials starts once you tap.\n"
      + "\n"
      + ">> Tips <<\n"
      + "Use the vibration to your advatage!\n"
      + "(You'll find you can go quite quickly.)\n"
      + "\n"
      + "It works best to start by aligning the centers,\n"
      + "then the crosshairs, then the sizes.\n";

    textAlign(CENTER, TOP);
    white.drawFill();
    text(message, vp.getCenter().x, vp.getCenter().y * 0.9);
  }
  else if (curTrial < numTrials) {
    // Draw viewport for clarity
    darkgray.drawFill();
    vp.draw();

    // Transform the curActual
    CRectangle curActual = trials.get(curTrial).actual;
    Vector2D delta = dragEnd.sub(dragStart);
    curActual = withTransformations(curActual, delta);

    // Draw the targets, optionally leaving things out if they're already correct
    Color lineColor;
    Color dotColor;
    // will be used further down
    boolean canProceed = true;
    if (curActual.isCloseDiam(target)) {
      brightblue.drawFill();
      lineColor = brightbluetrans;
      dotColor = brightbluetrans;

      controls.get("DIAM_DRAG").bg = blacklightrans;
      controls.get("DIAM_DRAG").fg = transparent;
    }
    else {
      blue.drawFill();
      lineColor = bluetrans;
      dotColor = bluetrans;

      controls.get("DIAM_DRAG").bg = blacktrans;
      controls.get("DIAM_DRAG").fg = white;

      canProceed = false;
    }
    target.draw();

    whitetrans.drawFill();
    curActual.draw();

    if (!curActual.isCloseCenter(target)) {
      white.drawFill();
      target.drawDot(dotRadius);
      dotColor.drawFill();
      curActual.drawDot(dotRadius);

      canProceed = false;
    }

    if (curActual.isCloseTheta(target)) {
      controls.get("THETA_DRAG").bg = blacklightrans;
      controls.get("THETA_DRAG").fg = transparent;
    }
    else {
      white.drawStroke();
      target.drawCrosshair();
      lineColor.drawStroke();
      curActual.drawCrosshair();

      controls.get("THETA_DRAG").bg = blacktrans;
      controls.get("THETA_DRAG").fg = white;

      canProceed = false;
    }

    // Turn NEXT button green when we're all correct
    if (canProceed) {
      controls.get("NEXT").bg = green;
    }
    else {
      controls.get("NEXT").bg = black;
    }

    // Draw all the controls
    for (Control c : controls.values()) {
      c.draw();

      if (c.action.equals("DIAM_DRAG") || c.action.equals("THETA_DRAG")) {
        c.drawSlider();
      }
    }
  }
  else {
    String message = getResults();

    textAlign(CENTER, TOP);
    white.drawFill();
    text(message, vp.getCenter().x, vp.getCenter().y * 0.8);
  }
}

void mousePressed() {
  if (!hasStarted || curTrial >= numTrials) {
    dragStart = new Vector2D(mouseX, mouseY);
    dragEnd = new Vector2D(mouseX, mouseY);
  }
  else {
    String action = getAction();

    if (isValidAction(action)) {
      curAction = action;
      if (isDragAction(action)) {
        dragStart = new Vector2D(mouseX, mouseY);
        dragEnd = new Vector2D(mouseX, mouseY);
      }
    }
  }
}

void mouseDragged() {
  if (!hasStarted) {
    dragEnd = new Vector2D(mouseX, mouseY);
    Vector2D delta = dragEnd.sub(dragStart);

    deltaTrials = (int) (-delta.y / i2p(0.25));
  }
  else if (curTrial < numTrials) {
    if (!curAction.equals("")) {
      dragEnd = new Vector2D(mouseX, mouseY);

      String action = getAction();
      // If we've moved from one of the sliders/buttons into the main drag area,
      // treat this as a center drag event.
      if (!curAction.equals("CENTER_DRAG") &&
          (action.equals("CENTER_DRAG") ||
           curAction.equals("NEXT"))) {
        curAction = action;
        dragStart = new Vector2D(mouseX, mouseY);
        dragEnd = new Vector2D(mouseX, mouseY);
      }
    }

    // Check for vibration
    Vector2D delta = dragEnd.sub(dragStart);
    CRectangle curActual = trials.get(curTrial).actual;
    curActual = withTransformations(curActual, delta);

    boolean newCenterCorrect = curActual.isCloseCenter(target);
    boolean newThetaCorrect  = curActual.isCloseTheta(target);
    boolean newDiamCorrect   = curActual.isCloseDiam(target);

    if (newCenterCorrect != hasCenterCorrect) {
      vibe.vibrate(vibeDuration);
    }
    else if (newThetaCorrect != hasThetaCorrect) {
      vibe.vibrate(vibeDuration);
    }
    else if (newDiamCorrect != hasDiamCorrect) {
      vibe.vibrate(vibeDuration);
    }

    hasCenterCorrect = newCenterCorrect;
    hasThetaCorrect = newThetaCorrect;
    hasDiamCorrect = newDiamCorrect;
  }
  else {
    dragEnd = new Vector2D(mouseX, mouseY);
  }
}

void mouseReleased() {
  if (!hasStarted) {
    // Add one trial for every half inch you move up
    numTrials += deltaTrials;
    if (numTrials < 1) {
      numTrials = 1;
    }

    if (deltaTrials == 0) {
      // Only start when the number of trials hasn't changed
      resetTrials();

      hasStarted = true;
      trials.get(curTrial).start();
    }
    else {
      deltaTrials = 0;
    }
  }
  else if (curTrial < numTrials) {
    if (curAction.equals("NEXT")) {
      performNext();
    }
    else if (curAction.equals("CENTER_DRAG") ||
             curAction.equals("THETA_DRAG") ||
             curAction.equals("DIAM_DRAG")) {
      performTransformations();
    }

    curAction = "";
    dragStart = new Vector2D();
    dragEnd = new Vector2D();
  }
  else {
    if (dragStart.equals(dragEnd)) {
      resetSetup();
    }

    dragStart = new Vector2D();
    dragEnd = new Vector2D();
  }
}

// ----- action dispatchers ---------------------------------------------------

void performNext() {
  if (curTrial < numTrials) {
    trials.get(curTrial).stop();
    curTrial++;
  }

  if (curTrial < numTrials) {
    CRectangle curActual = trials.get(curTrial).actual;
    hasCenterCorrect = curActual.isCloseCenter(target);
    hasThetaCorrect  = curActual.isCloseTheta(target);
    hasDiamCorrect   = curActual.isCloseDiam(target);

    trials.get(curTrial).start();
  }
}

void performTransformations() {
  Vector2D delta = dragEnd.sub(dragStart);
  CRectangle curActual = trials.get(curTrial).actual;
  trials.get(curTrial).actual = withTransformations(curActual, delta);
}

// ----- helpers --------------------------------------------------------------

int i2p(float x) {
  return (int) (x * DPI);
}

void resetTrials() {
  trials = new ArrayList<Trial>();

  for(int i = 0; i < numTrials; i++) {
    CRectangle cur = new CRectangle();
    cur.d     = sq(random(3.7f, 22.5f));
    cur.c.x   = random(vp.start.x + cur.d, vp.getRightX() - cur.d);
    cur.c.y   = random(vp.start.y + cur.d, vp.getBottomY() - cur.d);
    cur.theta = random(0, 90);
    trials.add(new Trial(cur, target));
  }
}

void resetSetup() {
  curTrial = 0;
  deltaTrials = 0;
  hasStarted = false;

  curAction = "";
  dragStart = new Vector2D();
  dragEnd   = new Vector2D();

  hasCenterCorrect = false;
  hasThetaCorrect = false;
  hasDiamCorrect = false;

  resetTrials();
}

String getAction() {
  for (Control c : controls.values()) {
    if (c.region.contains(mouseX, mouseY)) {
      return c.action;
    }
  }

  return "";
}

boolean isValidAction(String action) {
  return controls.containsKey(action);
}

boolean isDragAction(String action) {
  return action.contains("_DRAG");
}

CRectangle withTransformations(CRectangle base, Vector2D delta) {
  if (curAction.equals("CENTER_DRAG")) {
    base = base.translateCenter(delta);
  }
  else if (curAction.equals("THETA_DRAG")) {
    base = base.rotateTheta(delta, controls.get("THETA_DRAG").region.size);
  }
  else if (curAction.equals("DIAM_DRAG")) {
    base = base.scaleDiam(delta);
  }

  return base;
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
}

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

  void drawFill() {
    if (this.hsb) {
      colorMode(HSB, 360, 100, 100, 1);
    }
    else {
      colorMode(RGB, 255, 255, 255, 1);
    }

    fill(r, g, b, a);
  }

  void drawStroke() {
    if (this.hsb) {
      colorMode(HSB, 360, 100, 100, 1);
    }
    else {
      colorMode(RGB, 255, 255, 255, 1);
    }

    stroke(r, g, b, a);
  }
}

class Rectangle {
  public Vector2D start;
  public Vector2D size;

  Rectangle(Vector2D start, Vector2D size) {
    this.start = start;
    this.size  = size;
  }

  Vector2D getCenter() {
    return start.add(size.scale(0.5));
  }

  float getRightX() {
    return start.x + size.x;
  }
  float getBottomY() {
    return start.y + size.y;
  }

  boolean contains(float x, float y) {
    return (start.x <= x && x <= start.x + size.x) &&
           (start.y <= y && y <= start.y + size.y);
  }

  void draw() {
    rectMode(CORNER);
    rect(start.x, start.y, size.x, size.y);
  }

  void drawMainAxis() {
    pushMatrix();
    strokeWeight(dotRadius / 2.);

    translate(getCenter().x, getCenter().y);

    float s = i2p(0.15);
    float h = i2p(0.08);
    float b = i2p(0.04);

    if (size.x > size.y) {
      line(-size.x/2 + i2p(0.2), 0, size.x/2 - i2p(0.2), 0);
      noStroke();

      triangle(
          -size.x/2 + s + 0,  0,
          -size.x/2 + s + h,  b,
          -size.x/2 + s + h, -b);

      triangle(
         size.x/2 - s - 0,  0,
         size.x/2 - s - h,  b,
         size.x/2 - s - h, -b);
    }
    else {
      line(0, -size.y/2 + i2p(0.2), 0, size.y/2 - i2p(0.2));
      //-
      line(-b, size.y/2-i2p(0.1) , b, size.y/2-i2p(0.1));
      //+
      line(-b, -size.y/2+i2p(0.1) , b, -size.y/2+i2p(0.1));
      line(0, -size.y/2+i2p(0.06) , 0, -size.y/2 + i2p(0.14));


      noStroke();

      triangle(
           0, -size.y/2 + s + 0,
           b, -size.y/2 + s + h,
          -b, -size.y/2 + s + h);

      triangle(
           0, size.y/2 - s - 0,
           b, size.y/2 - s - h,
          -b, size.y/2 - s - h);
    }

    popMatrix();
  }
}

class CRectangle {
  public Vector2D c;
  public float theta;
  public float d;

  CRectangle() {
    this.c = new Vector2D(0, 0);
    this.theta = 0;
    this.d = 0;
  }

  CRectangle(CRectangle that) {
    this.c     = new Vector2D(that.c);
    this.theta = ((that.theta % 90) + 90) % 90;
    this.d     = that.d;
  }

  float getCenterDiff(CRectangle that) {
    return dist(this.c.x, this.c.y, that.c.x, that.c.y);
  }
  boolean isCloseCenter(CRectangle that) {
    return getCenterDiff(that) < i2p(0.05f);
  }

  float getThetaDiff(CRectangle that) {
    float angle = this.theta - that.theta;
    angle = ((angle % 90) + 90) % 90;
    return Math.min(angle, 90 - angle);
  }
  boolean isCloseTheta(CRectangle that) {
    return getThetaDiff(that) < 5;
  }

  float getDiamDiff(CRectangle that) {
    return abs(this.d - that.d);
  }
  boolean isCloseDiam(CRectangle that) {
    return getDiamDiff(that) < i2p(0.05f);
  }

  CRectangle translateCenter(Vector2D delta) {
    CRectangle result = new CRectangle(this);
    result.c = result.c.add(delta);
    return result;
  }

  CRectangle rotateTheta(Vector2D delta, Vector2D size) {
    float maxScale = size.x;
    CRectangle result = new CRectangle(this);
    result.theta -= (delta.x / (0.9 * maxScale)) * 180;
    result.theta = ((result.theta % 90) + 90) % 90;
    return result;
  }

  CRectangle scaleDiam(Vector2D delta) {
    CRectangle result = new CRectangle(this);
    result.d -= 0.8 * delta.y;
    if (result.d < 0) {
      result.d = 0;
    }
    return result;
  }

  void draw() {
    pushMatrix();

    rectMode(CENTER);

    translate(c.x, c.y);
    rotate(radians(this.theta));
    rect(0, 0, d, d);

    popMatrix();
  }

  void drawDot(float radius) {
    ellipseMode(RADIUS);
    ellipse(c.x, c.y, radius, radius);
  }

  void drawCrosshair() {
    pushMatrix();

    strokeWeight(dotRadius / 2.);

    translate(c.x, c.y);
    rotate(radians(this.theta));
    line(-d/2, 0, d/2, 0);
    line(0, -d/2, 0, d/2);

    noStroke();

    popMatrix();
  }
}

class Trial {
  public int startTime;
  public int endTime;

  public CRectangle target;
  public CRectangle actual;

  Trial(CRectangle actual, CRectangle target) {
    this.actual = actual;
    this.target = target;
  }

  void start() {
    this.startTime = millis();
  }
  void stop() {
    this.endTime = millis();
  }

  // Returns 1 if there was an error, else 0
  int getError() {
    if (actual.isCloseCenter(target) &&
        actual.isCloseTheta(target) &&
        actual.isCloseDiam(target)) {
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

class Control {
  public String action;
  public Color bg;
  public Color fg;
  public Rectangle region;

  Control(String action, Color bg, Color fg, Rectangle region) {
    this.action = action;
    this.bg     = bg;
    this.fg     = fg;
    this.region = region;
  }

  void draw() {
    bg.drawFill();
    region.draw();
  }

  void drawSlider() {
    fg.drawFill();
    fg.drawStroke();
    region.drawMainAxis();
  }
}