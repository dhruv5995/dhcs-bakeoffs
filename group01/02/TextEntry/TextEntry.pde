import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.regex.Pattern;
import java.util.Stack;

import android.content.Context;
import android.os.Vibrator;

String[] chars = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"};
ArrayList<Polygon> spinner = new ArrayList<Polygon>();

HashMap<String, Control> controls = new HashMap<String, Control>();

String[] phrases;
ArrayList<Trial> trials;

boolean resetUndo = false;
Stack<String> undoStack = new Stack<String>();

// box
Polygon watchFace;
final int DPI = 445;
// circles
int R = (DPI / 2) - 15;
int r = R - 100;
// phrase text
int fontSize = 42;
int pad = 12;
// triangle width
int base = (int) (DPI - Math.sqrt(2) * (R + pad));

String curLetter = "";
String curPhrase = "";

// Grading and timing code
boolean hasStarted = false;
int curTrial = 0;
int numTrials = 4;

final int blinkSpeed = 900;

final int vibeDuration = 18;
Vibrator vibe;

// predictive things
Predictor oracle;
String curSuffix;

void setup() {
  phrases = loadStrings("phrases.txt");
  oracle = new Predictor("words-300K.txt", 5);
  vibe = (Vibrator) getActivity().getSystemService(Context.VIBRATOR_SERVICE);

  orientation(PORTRAIT);
  textFont(createFont("Arial", 26));
  noStroke();

  // "restart" does some of the things we need to do at the very start as well
  performRestart();

  watchFace = new Polygon(new int[]{
    (width / 2) - (DPI / 2),
    (width / 2) + (DPI / 2),
    (width / 2) + (DPI / 2),
    (width / 2) - (DPI / 2),
  }, new int[]{
    (height / 2) - (DPI / 2),
    (height / 2) - (DPI / 2),
    (height / 2) + (DPI / 2),
    (height / 2) + (DPI / 2),
  }, 4);

  // Build up alphabet buttons
  double delta = (2 * Math.PI) / 26;
  for (int i = 0; i < 26; i++) {
    double theta = (-Math.PI / 2.) + delta * i;
    int[] xpoints = {
      (int) (r * Math.cos(theta)),
      (int) (R * Math.cos(theta)),
      (int) (R * Math.cos(theta + delta)),
      (int) (r * Math.cos(theta + delta)),
    };
    int[] ypoints = {
      (int) (r * Math.sin(theta)),
      (int) (R * Math.sin(theta)),
      (int) (R * Math.sin(theta + delta)),
      (int) (r * Math.sin(theta + delta)),
    };
    spinner.add(new Polygon(xpoints, ypoints, 4));
  }

  // Build up controls
  controls.put("BACKWORD",
      new Control("BACKWORD", "⌫⌫", 32, new Polygon(new int[] {
    (width / 2) - (DPI/2),               // top left
    (width / 2) - (DPI/2),
    (width / 2) - (DPI/2) + base,
  }, new int[]{
    (height / 2) - (DPI/2) + base,
    (height / 2) - (DPI/2),
    (height / 2) - (DPI/2),
  }, 3)));
  controls.put("BACKSPACE",
      new Control("BACKSPACE", "⌫", 42, new Polygon(new int[] {
    (width / 2) + (DPI/2) - base,        // top right
    (width / 2) + (DPI/2),
    (width / 2) + (DPI/2),
  }, new int[]{
    (height / 2) - (DPI/2),
    (height / 2) - (DPI/2),
    (height / 2) - (DPI/2) + base,
  }, 3)));
  controls.put("UNDO",
      new Control("UNDO", "↶", 56, new Polygon(new int[] {
    (width / 2) + (DPI/2),                // bottom right
    (width / 2) + (DPI/2),
    (width / 2) + (DPI/2) - base,
  }, new int[]{
    (height / 2) + (DPI/2) - base,
    (height / 2) + (DPI/2),
    (height / 2) + (DPI/2),
  }, 3)));
  controls.put("SPACE",
      new Control("SPACE", "␣", 56, new Polygon(new int[] {
    (width / 2) - (DPI/2) + base,         // bottom left
    (width / 2) - (DPI/2),
    (width / 2) - (DPI/2),
  }, new int[]{
    (height / 2) + (DPI/2),
    (height / 2) + (DPI/2),
    (height / 2) + (DPI/2) - base,
  }, 3)));

  int[] xpoints = new int[26];
  int[] ypoints = new int[26];
  for (int i = 0; i < 26; i++) {
    double theta = (-(Math.PI - delta) / 2) + delta * i;
    xpoints[i] = (int) ((width / 2)  + (r * Math.cos(theta)));
    ypoints[i] = (int) ((height / 2) + (r * Math.sin(theta)));
  }
  controls.put("AUTO",
      new Control("AUTO", "✔", 56, new Polygon(xpoints, ypoints, 26)));

  controls.put("NEXT",
      new Control("NEXT", "➡", 60, new Polygon(new int[] {
    (width / 2) + (DPI/2) + 40,
    (width / 2) + (DPI/2) + 40 + 150,
    (width / 2) + (DPI/2) + 40 + 150,
    (width / 2) + (DPI/2) + 40,
  }, new int[]{
    (height / 2) + (DPI / 2) - 150,
    (height / 2) + (DPI / 2) - 150,
    (height / 2) + (DPI / 2),
    (height / 2) + (DPI / 2),
  }, 4)));

  controls.put("RESTART",
      new Control("RESTART", "(restart)", 42, new Polygon(new int[] {
    0, width, width, 0,
  }, new int[] {
    0, 0, 100, 100,
  }, 4)));
}

void drawPolygon(Polygon p) {
  beginShape();
  for (int i = 0; i < p.npoints; i++) {
    vertex(p.xpoints[i], p.ypoints[i]);
  }
  endShape();
}

// Gets letter by searching bounds. Translates (mouseX, mouseY) into the region
// centered around (0, 0)
String getLetter() {
  int i = 0;
  for (Polygon p : spinner) {
    if (p.contains(mouseX - (width / 2), mouseY - (height / 2))) {
      return chars[i].toLowerCase();
    }
    i++;
  }

  // Handles the "SPACE" control as a letter
  if (controls.get("SPACE").region.contains(mouseX, mouseY)) {
    return " ";
  }

  return "";
}

void updateCurrentLetter() {
  String newLetter = getLetter();
  newLetter = newLetter == "_" ?  " " : newLetter;
  if (newLetter != "" && !newLetter.equals(curLetter)) {
    vibe.vibrate(vibeDuration);
  }
  curLetter = newLetter;
}

// Gets the control under (mouseX, mouseY) after shifting it into the region
// centered around (0, 0)
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

// Gets the current word prefix by substringing from the last index of space
String getPrefix() {
  int spaceIdx = curPhrase.lastIndexOf(" ");
  return curPhrase.substring(spaceIdx + 1, curPhrase.length()) + curLetter;
}

void draw() {
  //clear background
  background(0);

  // Shift frame of reference to center of screen
  translate(width / 2, height / 2);

  // Draw 1" box in center
  fill(100);
  rectMode(CENTER);
  rect(0, 0, DPI, DPI);

  // Draw ring
  textAlign(CENTER, CENTER);
  fill(255);
  ellipseMode(RADIUS);
  ellipse(0, 0, R, R);
  fill(0, 122, 255);
  ellipse(0, 0, r, r);

  // Draw spinner
  textSize(28);
  ArrayList<String> likelyLetters = oracle.getLikelyLetters(getPrefix());
  int i = 0;
  for (Polygon p : spinner) {
    // default foreground color (might be overriden below)
    fill(0, 122, 255);

    // draw background if it's a likely letter
    if (likelyLetters.size() > 0 &&
        likelyLetters.get(0).equalsIgnoreCase(chars[i])) {
      fill(0, 122, 255);
      ellipse(p.getCenterX(), p.getCenterY(), 28, 28);
      fill(255);
      // shift off this one (likelyLetters is sorted)
      likelyLetters.remove(0);
    }

    text(chars[i], p.getCenterX(), p.getCenterY());

    i++;
  }

  translate(- width / 2, - height / 2);
  // Draw controls
  for (Control c : controls.values()) {
    // get background
    fill(255);
    if (c.action.equals("BACKSPACE") ||
        c.action.equals("SPACE")) {
      fill(0, 122, 255);
    }
    else if (c.action.equals("RESTART")) {
      if (curTrial < numTrials) {
        fill(0, 122, 255);
      }
      else {
        fill(68, 163, 0);
      }
    }
    else if (c.action.equals("NEXT")) {
      fill(68, 163, 0);
    }

    // draw background (autocomplete circle is drawn earlier)
    if (!c.action.equals("AUTO")) {
      drawPolygon(c.region);
    }

    // get foreground
    fill(0, 122, 255);
    if (c.action.equals("BACKSPACE") ||
        c.action.equals("SPACE") ||
        c.action.equals("AUTO") ||
        c.action.equals("NEXT") ||
        c.action.equals("RESTART")) {
      fill(255);
    }

    // draw foreground
    textSize(c.fontSize);
    text(c.symbol, c.region.getCenterX(), c.region.getCenterY());
  }
  translate(width / 2, height / 2);

  // Draw text left-aligned, and centered over the box
  // above square
  rectMode(CORNER);
  textAlign(LEFT, TOP);
  textSize(fontSize);

  if (curTrial < numTrials) {
    float phraseWidth = textWidth(trials.get(curTrial).targetPhrase);
    pushMatrix();
    translate(-(phraseWidth / 2) - pad, -(DPI / 2) - (2 * fontSize + 3 * pad));

    fill(255);
    rect(0, 0, phraseWidth + (2 * pad), (2 * fontSize + 2 * pad));

    fill(0, 122, 255);
    text(trials.get(curTrial).targetPhrase, pad, pad);
    text(curPhrase + curLetter,             pad, pad + fontSize + pad);

    // cursor
    phraseWidth = textWidth(curPhrase + curLetter);
    if (millis() % (2 * blinkSpeed) < blinkSpeed || mousePressed) {
      stroke(0);
      line(pad + phraseWidth, pad + fontSize + pad,
           pad + phraseWidth, pad + fontSize + pad + fontSize);
      noStroke();
    }

    // autocompletion
    fill(130, 136, 166);
    curSuffix = oracle.getLikelySuffix(getPrefix());
    text(curSuffix, pad + phraseWidth, pad + fontSize + pad);

    popMatrix();
  }

  // below square
  String message;
  if (!hasStarted) {
    message = "Your first of " + numTrials + " trials starts once you begin entering text.\n";
  }
  else if (curTrial < numTrials) {
    if (curTrial == 0) {
      message = "Waiting for trial stats...\n";
    }
    else {
      message = trials.get(curTrial - 1).toString();
    }
  }
  else {
    message = "Results:\n"
      + "total time:        " + getTotalTime()              + "\n"
      + "letters entered:   " + getTotalEnteredLetters()    + "\n"
      + "letters expected:  " + getTotalExpectedLetters()   + "\n"
      + "total errors:      " + getTotalErrors()            + "\n"
      + "words/minute:      " + getWPM();
  }

  textAlign(CENTER, TOP);
  fill(255);
  text(message, 0, (DPI / 2) + (4 * pad));
}

void performBackword() {
  pushUndo(curPhrase);
  // "remove" last word (until space)
  if (curPhrase.length() > 0) {
    int spaceIdx = curPhrase.lastIndexOf(" ");
    curPhrase = curPhrase.substring(0, spaceIdx + 1);
  }
}

void performBackspace() {
  pushUndo(curPhrase);
  // "remove" last char
  if (curPhrase.length() > 0) {
    curPhrase = curPhrase.substring(0, curPhrase.length() - 1);
  }
}

void pushUndo(String phrase) {
  if (resetUndo) {
    resetUndo = false;
    undoStack = new Stack<String>();
  }
  undoStack.push(phrase);
}
String popUndo() {
  resetUndo = true;
  if (!undoStack.empty()) {
    return undoStack.pop();
  }
  else {
    return "";
  }
}
void clearUndo() {
  resetUndo = false;
  undoStack = new Stack<String>();
}

void performUndo() {
  String last = popUndo();
  if (!last.equals("")) {
    curPhrase = last;
  }
}

void performAutocomplete() {
  pushUndo(curPhrase);
  curPhrase += curSuffix + " ";
  curSuffix = "";
}

void performNext() {
  if (curTrial < numTrials) {
    trials.get(curTrial).stop(curPhrase);
    curPhrase = "";
    clearUndo();
    curTrial++;
  }

  if (curTrial < numTrials) {
    trials.get(curTrial).start();
  }
}

void performRestart() {
  curTrial = 0;
  curPhrase = "";
  hasStarted = false;
  Collections.shuffle(Arrays.asList(phrases));
  trials = new ArrayList<Trial>();
  for (int i = 0; i < numTrials; i++) {
    trials.add(new Trial(phrases[i]));
  }
}


void mouseDragged() {
  updateCurrentLetter();
}

void mousePressed() {
  updateCurrentLetter();
  String action = getAction();

  if (!hasStarted) {
    // Start
    if (!watchFace.contains(mouseX, mouseY) && !isValidAction(action)) {
      // tap right side to increment, tap left side to decrement
      if (mouseX - (width / 2) > 0) {
        trials.add(new Trial(phrases[(numTrials++) % phrases.length]));
      }
      else {
        if (numTrials > 1) {
          trials.remove(--numTrials);
        }
      }
    }
    else {
      // Let's go!
      hasStarted = true;
      trials.get(curTrial).start();
    }
  }

  if (isValidAction(action)) {
    vibe.vibrate(vibeDuration);
  }
}

void mouseReleased() {
  updateCurrentLetter();
  if (!curLetter.equals("")) {
    pushUndo(curPhrase);
    curPhrase += curLetter == "_" ?  " " : curLetter;
    curLetter = "";
  }

  String action = getAction();
  if (action.equals("BACKWORD")) {
    curPhrase = curPhrase.trim();
    performBackword();
  }
  else if (action.equals("BACKSPACE")) {
    performBackspace();
  }
  else if (action.equals("UNDO")) {
    performUndo();
  }
  else if (action.equals("NEXT")) {
    performNext();
  }
  else if (action.equals("AUTO")) {
    performAutocomplete();
  }
  else if (action.equals("RESTART")) {
    performRestart();
  }
}


class Rectangle {
  public int x;
  public int y;
  public int width;
  public int height;

  Rectangle(int x, int y, int width, int height) {
    this.x      = x;
    this.y      = y;
    this.width  = width;
    this.height = height;
  }

  int getCenterX() {
    return x + width / 2;
  }

  int getCenterY() {
    return y + height / 2;
  }
}

class Polygon {
  public int[] xpoints;
  public int[] ypoints;
  public int   npoints;

  Polygon(int[] xpoints, int[] ypoints, int npoints) {
    this.xpoints = xpoints;
    this.ypoints = ypoints;
    this.npoints = npoints;
  }

  // Determine if under the edge formed by
  // (xpoints[i], ypoints[i]) -> (xpoints[i+1], ypoints[i+1])
  private boolean under_edge(int i, int x, int y) {
    int dX = xpoints[(i+1) % npoints] - xpoints[i % npoints];
    int dY = ypoints[(i+1) % npoints] - ypoints[i % npoints];

    return (y - ypoints[i % npoints]) * dX -
      (x - xpoints[i % npoints]) * dY >= 0;
  }

  // Check if point in shape
  public boolean contains(int x, int y) {
    boolean result = true;
    for (int i = 0; i < npoints; i++) {
      result &= under_edge(i, x, y);
    }

    return result;
  }

  int getCenterX() {
    int sum = 0;
    for (int x : xpoints) sum += x;
    return sum / npoints;
  }

  int getCenterY() {
    int sum = 0;
    for (int y : ypoints) sum += y;
    return sum / npoints;
  }

  Rectangle getBounds() {
    int minX = 0x7fffffff;
    int maxX = 0x80000000;
    int minY = 0x7fffffff;
    int maxY = 0x80000000;

    for (int i = 0; i < npoints; i++) {
      if (xpoints[i] < minX) minX = xpoints[i];
      if (xpoints[i] > maxX) maxX = xpoints[i];
      if (ypoints[i] < minY) minY = ypoints[i];
      if (ypoints[i] > maxY) maxY = ypoints[i];
    }

    return new Rectangle(minX, minY, maxX - minX, maxY - minY);
  }
}

class Trial {
  public int startTime;
  public int endTime;

  public String targetPhrase;
  public String enteredPhrase;

  Trial(String targetPhrase) {
    this.targetPhrase = targetPhrase.trim();
  }

  void start() {
    this.startTime = millis();
  }
  void stop(String enteredPhrase) {
    this.endTime = millis();
    this.enteredPhrase = enteredPhrase.trim();
  }

  // Computes Levenshtein min edit distance
  int getErrors() {
    int n = this.targetPhrase.length();
    int m = this.enteredPhrase.length();
    int[][] distance = new int[n + 1][m + 1];

    for (int i = 0; i <= n; i++)
      distance[i][0] = i;
    for (int j = 1; j <= m; j++)
      distance[0][j] = j;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        boolean doesDiffer = (this.targetPhrase.charAt(i-1) == this.enteredPhrase.charAt(j-1));

        distance[i][j] = min(min(distance[i-1][j] + 1, distance[i][j-1] + 1),
            distance[i-1][j-1] + (doesDiffer ? 0 : 1));
      }
    }

    return distance[n][m];
  }

  int getTime() {
    return this.endTime - this.startTime;
  }

  String toString() {
    return "\n"
      + "target phrase:  " + this.targetPhrase           + "\n"
      + "       length:  " + this.targetPhrase.length()  + "\n"
      + "entered phrase: " + this.enteredPhrase          + "\n"
      + "        length: " + this.enteredPhrase.length() + "\n"
      + "no. of errors:  " + getErrors()                 + "\n"
      + "time taken:     " + getTime()                   + "\n";
  }
}

class Control {
  public String action;
  public String symbol;
  public int fontSize;
  public Polygon region;

  Control(String action, String symbol, int fontSize, Polygon region) {
    this.action = action;
    this.symbol = symbol;
    this.fontSize = fontSize;
    this.region = region;
  }
}


int getTotalTime() {
  int result = 0;
  for (Trial t : trials) {
    result += t.getTime();
  }
  return result;
}

int getTotalEnteredLetters() {
  int result = 0;
  for (Trial t : trials) {
    result += t.enteredPhrase.length();
  }
  return result;
}

int getTotalExpectedLetters() {
  int result = 0;
  for (Trial t : trials) {
    result += t.targetPhrase.length();
  }
  return result;
}

int getTotalErrors() {
  int result = 0;
  for (Trial t : trials) {
    result += t.getErrors();
  }
  return result;
}

double getWPM() {
  double words = getTotalEnteredLetters() / 5.;
  double minutes = getTotalTime() / (1. * 60 * 1000);

  return words / minutes;
}

class TrieNode {
  boolean isRoot;
  public String character;
  public String target;
  public ArrayList<TrieNode> children;

  TrieNode() {
    this.isRoot = true;
    this.character = "";
    this.target = "";
    this.children = new ArrayList<TrieNode>();;
  }

  TrieNode(String character, String suffix, String target) {
    this.isRoot = false;
    this.character = character;
    this.target = target;
    this.children = new ArrayList<TrieNode>();;

    add(suffix, target);
  }

  TrieNode getByChar(String character) {
    for (TrieNode child : children) {
      if (child.character.equals(character)) {
        return child;
      }
    }

    return null;
  }

  void add(String target) {
    add(target, target);
  }

  void add(String suffix, String target) {
    if (suffix.length() == 0) return;
    if (isRoot && this.target.equals("")) {
      this.target = suffix;
    }

    String character = suffix.substring(0, 1);
    String substring = suffix.substring(1, suffix.length());

    TrieNode child = getByChar(character);
    if (child != null) {
      child.add(substring, target);
    }
    else {
      children.add(new TrieNode(character, substring, target));
    }
  }

  TrieNode find(String prefix) {
    if (prefix.length() == 0) return null;

    if (this.isRoot) {
      for (TrieNode node : children) {
        TrieNode result = node.find(prefix);
        if (result != null) return result;
      }
      return null;
    }
    else {
      String character = prefix.substring(0, 1);
      String substring = prefix.substring(1, prefix.length());

      if (character.equals(this.character)) {
        for (TrieNode node : children) {
          TrieNode result = node.find(substring);
          if (result != null) return result;
        }
        return this;
      }
      else {
        return null;
      }
    }
  }

  String toString(String prefix) {
    String result = "";
    result += prefix + "target: <" + this.target + ">\n";
    result += prefix + "char: <" + this.character + ">\n";
    for (TrieNode child : children) {
      result += child.toString(prefix + "  ");
    }
    return result;
  }
  public String toString() {
    return this.toString("");
  }
}

public class Predictor {
  //String[] corpus;
  int maxLetters;
  public TrieNode corpus;

  Predictor(String words_file, int maxLetters) {
    String[] words = loadStrings(words_file);
    this.corpus = new TrieNode();
    for (String word : words) {
      this.corpus.add(word);
    }
    this.maxLetters = maxLetters;
  }

  String getLikelyWord(String prefix) {
    TrieNode result = corpus.find(prefix);
    return result == null ? prefix : result.target;
  }

  String getLikelySuffix(String prefix) {
    String likelyWord = getLikelyWord(prefix);
    if (likelyWord.length() < prefix.length()) {
      return "";
    }
    else {
      return likelyWord.substring(prefix.length(), likelyWord.length());
    }
  }

  ArrayList<String> getLikelyLetters(String prefix) {
    TrieNode node = corpus.find(prefix);
    if (node != null) {
      ArrayList<TrieNode> children = node.children;
      ArrayList<String> result = new ArrayList<String>();

      int i = 0;
      for (TrieNode child : children) {
        result.add(child.character);
        if (++i >= this.maxLetters) break;
      }

      Collections.sort(result);
      return result;
    }
    else {
      return new ArrayList<String>(Arrays.asList(new String[] {"a", "e", "h", "n", "t"}));
    }
  }
}
