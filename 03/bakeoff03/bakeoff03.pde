import java.util.ArrayList;
import java.util.Collections;

int index = 0;

//your input code should modify these!!
float screenTransX = 0;
float screenTransY = 0;
float screenRotation = 0;
float screenZ = 50f;

int trialCount = 4; //this will be set higher for the bakeoff
int border = 10; //have some padding from the sides
int trialIndex = 0;
int errorCount = 0;
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;

private class Target
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Target> targets = new ArrayList<Target>();

void setup() {
  size(500, 500);
  rectMode(CENTER);
  textFont(createFont("Arial", 24)); //sets the font to Arial size 16
  textAlign(CENTER);

  for (int i=0; i<trialCount; i++)
  {
    Target t = new Target();
    t.x = random(-width/2+border, width/2-border);
    t.y = random(-height/2+border, height/2-border);
    t.rotation = random(0, 360);
    t.z = sq(random(2.7f, 22.5f));
    targets.add(t);
    println("created target with " + t.x + "," + t.y + "," + t.rotation + "," + t.z);
  }

  Collections.shuffle(targets); // randomize the order of the button;
}

void draw() {

  background(0);
  fill(200);
  noStroke();

  if (startTime == 0)
    startTime = millis();

  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 60);
    text("User had " + errorCount + " error(s)", width/2, 90);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per target", width/2, 120);

    return;
  }

  //===========DRAW TARGET SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen

  Target t = targets.get(trialIndex);


  translate(t.x, t.y); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY); //center the drawing coordinates to the center of the screen

  rotate(radians(t.rotation));

  fill(255, 0, 0); //set color to semi translucent
  rect(0, 0, t.z, t.z);

  fill(0);
  ellipse(0, 0, 3, 3);

  popMatrix();

  //===========DRAW TARGETTING SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  rotate(radians(screenRotation));

  //custom shifts:
  //translate(screenTransX,screenTransY); //center the drawing coordinates to the center of the screen

  fill(255, 128); //set color to semi translucent
  rect(0, 0, screenZ, screenZ);

  popMatrix();

  scaffoldControlLogic(); //you are going to want to replace this!

  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, 60);
}

void scaffoldControlLogic()
{
  //upper left corner, rotate counterclockwise
  text("CCW", 30, 30);
  if (mousePressed && dist(0, 0, mouseX, mouseY)<80)
    screenRotation--;

  //upper right corner, rotate clockwise
  text("CW", width-30, 30);
  if (mousePressed && dist(width, 0, mouseX, mouseY)<80)
    screenRotation++;

  //lower left corner, decrease Z
  text("-", 30, height-30);
  if (mousePressed && dist(0, height, mouseX, mouseY)<80)
    screenZ--;

  //lower right corner, increase Z
  text("+", width-30, height-30);
  if (mousePressed && dist(width, height, mouseX, mouseY)<80)
    screenZ++;

  //left middle, move left
  text("left", 30, height/2);
  if (mousePressed && dist(0, height/2, mouseX, mouseY)<80)
    screenTransX--;

  text("right", width-30, height/2);
  if (mousePressed && dist(width, height/2, mouseX, mouseY)<80)
    screenTransX++;

  text("up", width/2, 30);
  if (mousePressed && dist(width/2, 0, mouseX, mouseY)<80)
    screenTransY--;

  text("down", width/2, height-30);
  if (mousePressed && dist(width/2, height, mouseX, mouseY)<80)
    screenTransY++;
}

void mouseReleased()
{
  //check to see if user clicked middle of screen
  if (dist(width/2, height/2, mouseX, mouseY)<100)
  {
    if (userDone==false && !checkForSuccess())
      errorCount++;

    //and move on to next trial
    trialIndex++;

    screenTransX = 0;
    screenTransY = 0;

    if (trialIndex==trialCount && userDone==false)
    {
      userDone = true;
      finishTime = millis();
    }
  }
}

//function for testing if the overlap is sufficiently close
//Don't change this function! Check with Chris if you think you have to.
boolean checkForSuccess()
{
  Target t = targets.get(trialIndex);
  boolean closeDist = dist(t.x, t.y, -screenTransX, -screenTransY)<15;
  boolean closeRotation = abs(t.rotation - screenRotation)%90<7;
  boolean closeZ = abs(t.z - screenZ)<8;
  println("Close Enough Distance: " + closeDist);
  println("Close Enough Rotation: " + closeRotation);
  println("Close Enough Z: " + closeZ);

  return closeDist && closeRotation && closeZ;
}
