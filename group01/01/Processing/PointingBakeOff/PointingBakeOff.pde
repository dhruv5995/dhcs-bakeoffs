import java.awt.Rectangle;
import java.util.ArrayList;
import java.util.Collections;
import processing.core.PApplet;


// you SHOULD NOT need to edit any of these variables
int margin = 100; // margin from sides of window
final int padding = 35; // padding between buttons and also their width/height
ArrayList trials = new ArrayList(); //contains the order of buttons that activate in the test
int trialNum = 0; //the current trial number (indexes into trials array above)
int startTime = 0; // time starts when the first click is captured.
int userX = mouseX; //stores the X position of the user's cursor
int userY = mouseY; //stores the Y position of the user's cursor
int finishTime = 0; //records the time of the final click
int hits = 0; //number of succesful clicks
int misses = 0; //number of missed clicks

// You can edit variables below here and also add new ones as you see fit
int numRepeats = 10; //sets the number of times each button repeats in the test (you can edit this)

boolean showWelcome = true;

int participantId = 4;
int prevUserX = userX;
int prevUserY = userY;
int prevTime = 0;

void draw()
{
  background(0); //set background to black

  if (showWelcome)
  {
    String messages[] = {
      "Welcome!",
      "",
      "Here are some tips:",
      "",
      "1. Use two hands:",
      "   - one hand to move the cursor",
      "   - one finger to tap spacebar (or click, if you like)",
      "",
      "2. Click as soon as you see the box change size!",
      "",
      "3. The \"on deck\" button is lit up in a very dull",
      "   blue; use it to anticipate where to go next.",
      "",
      "4. Click anywhere to continue. The timer won't start",
      "   until you click on the first square, so take a ",
      "   deep breath and relax :)",
    };

    float maxWidth = 0;
    for (String message : messages) {
      maxWidth = Math.max(textWidth(message), maxWidth);
    }

    fill(255);
    textAlign(LEFT);
    for (int i = 0; i < messages.length; i++) {
      text(messages[i], (width - maxWidth) / 2, height / 2 + (20 * i) - 140);
    }
    textAlign(CENTER);
  }
  else
  {
    if (trialNum >= trials.size()) //check to see if test is over
    {
      fill(255); //set fill color to white
      //write to screen
      text("Finished!", width / 2, height / 2);
      text("Hits: " + hits, width / 2, height / 2 + 20);
      text("Misses: " + misses, width / 2, height / 2 + 40);
      text("Accuracy: " + (float)hits*100f/(float)(hits+misses) +"%", width / 2, height / 2 + 60);
      text("Total time taken: " + (finishTime-startTime) / 1000f + " sec", width / 2, height / 2 + 80);
      text("Average time for each button: " + ((finishTime-startTime) / 1000f)/(float)(hits+misses) + " sec", width / 2, height / 2 + 100);

      return; //return, nothing else to do now test is over
    }

    fill(255); //set fill color to white
    text((trialNum + 1) + " of " + trials.size(), 40, 20); //display what trial the user is on

    for (int i = 0; i < 16; i++)// for all button
      drawButton(i); //draw button

    //fill(255, 0, 0);
    //noCursor();
    //ellipse(userX, userY, 20, 20);
    ////triangle(userX, userY, userX + 0, userY + 25, userX + 17, userY + 17);

    // you shouldn't need to edit anything above this line! You can edit below this line as you see fit
  }
}

void mousePressed() // test to see if hit was in target!
{
  if (showWelcome) {
    showWelcome = false;
    return;
  }

  if (trialNum >= trials.size()) {
    return;
  }

  int curTime = millis();

  //check if first click
  if (trialNum == 0) {
    startTime = curTime;
    prevTime = startTime;
    prevUserX = userX;
    prevUserY = userY;
  }

  Rectangle bounds = getButtonLocation((Integer)trials.get(trialNum));
  Rectangle paddedBounds = getPaddedBounds(bounds);

  // YOU CAN EDIT BELOW HERE IF YOUR METHOD REQUIRES IT (shouldn't need to edit above this line)

  boolean isHit = isInBounds(bounds);
  if (isHit) // test to see if hit was within bounds
  {
    hits++;
  }
  else
  {
    misses++;
  }

  if (trialNum > 0) {
    System.out.println(trialNum
        + "," + participantId
        + "," + prevUserX
        + "," + prevUserY
        + "," + bounds.getCenterX()
        + "," + bounds.getCenterY()
        + "," + paddedBounds.width
        + "," + (curTime - prevTime)
        + "," + (isHit ? 1 : 0)
        );
    prevUserX = userX;
    prevUserY = userY;
    prevTime = curTime;
  }

  if (trialNum == trials.size() - 1) //check if final click
  {
    finishTime = curTime;
  }

  trialNum++; // Increment trial number
}

void keyPressed() {
  mousePressed();
}


void updateUserMouse() // YOU CAN EDIT THIS
{
  // you can do whatever you want to userX and userY (you shouldn't touch mouseX and mouseY)
  //userX += mouseX - pmouseX; //add to userX the difference between the current mouseX and the previous mouseX
  //userY += mouseY - pmouseY; //add to userY the difference between the current mouseY and the previous mouseY
  userX = mouseX;
  userY = mouseY;
}

Rectangle getPaddedBounds(Rectangle bounds) {
  int pad = padding / 2;
  return new Rectangle(bounds.x - pad, bounds.y - pad, bounds.width + pad, bounds.height + pad);
}

boolean isInBounds(Rectangle bounds) {
  return getPaddedBounds(bounds).contains(userX, userY);
}







// ===========================================================================
// =========SHOULDN'T NEED TO EDIT ANYTHING BELOW THIS LINE===================
// ===========================================================================

void setup()
{
  size(500,500,P2D); // set the size of the window
  //noCursor(); // hides the system cursor (can turn on for debug, but should be off otherwise!)
  noStroke(); //turn off all strokes, we're just using fills here (can change this if you want)
  noSmooth();
  textFont(createFont("Arial",16));
  textAlign(CENTER);
  frameRate(100);
  ellipseMode(CENTER); //ellipses are drawn from the center (BUT RECTANGLES ARE NOT!)
  // ====create trial order======
  for (int i = 0; i < 16; i++)
    // number of buttons in 4x4 grid
    for (int k = 0; k < numRepeats; k++)
      // number of times each button repeats
      trials.add(i);

  Collections.shuffle(trials); // randomize the order of the buttons
  System.out.println("trialNum,participantId,prevUserX,prevUserY,curCenterX,curCenterY,width,time,success");
}

Rectangle getButtonLocation(int i)
{
  double x = (i % 4) * padding * 2 + margin;
  double y = (i / 4) * padding * 2 + margin;

  return new Rectangle((int)x, (int)y, padding, padding);
}

void drawButton(int i)
{
  Rectangle bounds = getButtonLocation(i);

  int curButton = (Integer)trials.get(trialNum);

  int nextButton = -1;
  if (trialNum < trials.size() - 1) {
    nextButton = (Integer)trials.get(trialNum + 1);
  }

  //noFill();
  //stroke(200);
  //rect(bounds.x - (padding / 2.0), bounds.y - (padding / 2.0),
  //    bounds.width + padding, bounds.height + padding);
  //noStroke();

  if (i == curButton) { // see if current button is the target
    if (isInBounds(bounds)) // test to see if hit was within bounds
    {
      fill(0, 195, 255); // if so, fill bright cyan
      float pad = padding / 2.0;
      rect(bounds.x - pad, bounds.y - pad,
          bounds.width + 2 * pad, bounds.height + 2 * pad);

    }
    else
    {
      if (curButton == nextButton) {
        fill(0, 148, 12);
      }
      else {
        fill(0, 102, 133); // if so, fill dull cyan
      }
    }
  }
  else if (i == nextButton) {
    fill(0, 39, 51); // if not, fill gray
  }
  else {
    fill(100); // if not, fill gray
  }

  rect(bounds.x, bounds.y, bounds.width, bounds.height);
}

void mouseMoved() // Don't edit this
{
  updateUserMouse();
}

void mouseDragged() // Don't edit this
{
  updateUserMouse();
}

