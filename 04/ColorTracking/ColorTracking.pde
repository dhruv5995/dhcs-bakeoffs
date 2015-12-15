import ketai.camera.*;

KetaiCamera cam;
Vector2D bestLoc; // camera space

Color targetColor;
Color brightred = new Color(255, 0, 0);

// Camera constants
int fps = 16;
float fidelity = 0.5;
Vector2D maxRes = new Vector2D(1280, 960);
Vector2D scaledRes = maxRes.scale(fidelity);

void setup() {
  bestLoc = new Vector2D();
  orientation(LANDSCAPE);
  imageMode(CENTER);
  noStroke();
}

void draw() {
  background(0);

  if (cam != null && cam.isStarted()) {
    // Draw the webcam video onto the screen
    pushMatrix();
    translate(width/2, height/2);
    scale(-1, 1);
    image(cam, 0, 0, width, height);
    popMatrix();

    int x0 = (int) bestLoc.x;
    int y0 = (int) bestLoc.y;
    int maxR = max(cam.width, cam.height);

    PixelGuess bestPixelDistPair = new PixelGuess(0, 0, 3e30); // camera space

    // Have this run every so often, factor out of draw
    for (int r = 0; r < maxR; r++) {
      int x;
      int y = y0 - r;
      if (0 <= y) {
        for (x = x0 - r; x <= x0 + r; x++) {
          //System.out.println("x: " + x + " y: " + y);
          bestPixelDistPair = minDistAtPixel(x, y, bestPixelDistPair);
        }
      }

      x = x0 + r;
      if (x < width) {
        for (y = y0 - r + 1; y < y0 + r - 1; y++) {
          //System.out.println("x: " + x + " y: " + y);
          bestPixelDistPair = minDistAtPixel(x, y, bestPixelDistPair);
        }
      }

      y = y0 + r;
      if (y < height) {
        for (x = x0 - r; x <= x0 + r; x++) {
          //System.out.println("x: " + x + " y: " + y);
          bestPixelDistPair = minDistAtPixel(x, y, bestPixelDistPair);
        }
      }

      x = x0 - r;
      if (0 <= x) {
        for (y = y0 - r + 1; y < y0 + r - 1; y++) {
          //System.out.println("x: " + x + " y: " + y);
          bestPixelDistPair = minDistAtPixel(x, y, bestPixelDistPair);
        }
      }

      if (bestPixelDistPair.dist < 30) break;
    }
    bestLoc = new Vector2D(bestPixelDistPair.x, bestPixelDistPair.y);
    //int bestIndex = 0;
    //float bestDist = 3e30;
    //for (int y = 0; y < cam.height; y++) {
    //  for (int x = 0; x < cam.width; x++) {
    //    int curIndex = y*cam.width + x;

    //    Color curColor = new Color(cam.pixels[curIndex]);
    //    float curDist = targetColor.dist(curColor);

    //    // Check to see if you’ve found a better pixel match
    //    if (curDist < bestDist)
    //    {
    //      bestDist = curDist;
    //      bestIndex = curIndex;

    //      System.out.println("current best: " + curDist);

    //      if (bestDist < 30) {
    //        break;
    //      }
    //    }
    //  }
    //}

    Vector2D cameraLoc = new Vector2D(bestLoc.x, bestLoc.y);
    Vector2D screenLoc = reflectHorizontal(cameraToScreen(cameraLoc), width);

    // Draw circle on tracked point
    targetColor.drawFill();
    ellipseMode(CENTER);
    ellipse(screenLoc.x, screenLoc.y, 50, 50);
  }
}

void onCameraPreviewEvent() {
  cam.read();
}

Vector2D screenToCamera(Vector2D in) {
  return in.scale(cam.width, cam.height).scale(1. / width, 1. / height);
}
Vector2D cameraToScreen(Vector2D in) {
  return in.scale(width, height).scale(1. / cam.width, 1. / cam.height);
}
Vector2D reflectHorizontal(Vector2D in, float width) {
  return new Vector2D(width - in.x, in.y);
}

PixelGuess minDistAtPixel(int x, int y, PixelGuess in) {
  int curIndex = y*cam.width + x;
  //System.out.println("x: " + x + "y: " + y + "i: " + curIndex);

  if (!(0 <= curIndex && curIndex < cam.pixels.length)) return in;

  Color curColor = new Color(cam.pixels[curIndex]);
  float curDist = targetColor.dist(curColor);

  if (curDist < in.dist) {
    return new PixelGuess(x, y, curDist);
  }
  else {
    return in;
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

void mousePressed() {
  if (cam == null) {
    cam = new KetaiCamera(this, (int) scaledRes.x, (int) scaledRes.y, fps);
    cam.setCameraID(/* front-facing camera */ 1);
    cam.start();
  }

  Vector2D screenTap = new Vector2D(mouseX, mouseY);
  Vector2D cameraTap = screenToCamera(reflectHorizontal(screenTap, width));
  int cx = (int) cameraTap.x;
  int cy = (int) cameraTap.y;
  bestLoc = new Vector2D(cx, cy);
  targetColor = new Color(cam.pixels[cy*cam.width + cx]);
  System.out.println(targetColor);
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

  void draw() {
    rectMode(CORNER);
    rect(start.x, start.y, size.x, size.y);
  }
}
