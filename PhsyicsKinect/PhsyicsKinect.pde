// Kinect Physics Example by Amnon Owed (15/09/12)

// import libraries
import processing.opengl.*; // opengl
import SimpleOpenNI.*; // kinect
import blobDetection.*; // blobs
import toxi.geom.*; // toxiclibs shapes and vectors
import toxi.processing.*; // toxiclibs display
import pbox2d.*; // shiffman's jbox2d helper library
import org.jbox2d.collision.shapes.*; // jbox2d
import org.jbox2d.common.*; // jbox2d
import org.jbox2d.dynamics.*; // jbox2d
import java.util.Collections;

int MAX_SHAPES = 100;

// declare SimpleOpenNI object
SimpleOpenNI context;
// declare BlobDetection object
BlobDetection theBlobDetection;
// ToxiclibsSupport for displaying polygons
ToxiclibsSupport gfx;
// declare custom PolygonBlob object (see class for more info)
PolygonBlob poly;

boolean autoCalib=true;


// PImage to hold incoming imagery and smaller one for blob detection
PImage cam, blobs;
// the kinect's dimensions to be used later on for calculations
int kinectWidth = 640;
int kinectHeight = 480;
// to center and rescale from 640x480 to higher custom resolutions
float reScale;

// background and blob color
color bgColor, blobColor;
// three color palettes (artifact from me storing many interesting color palettes as strings in an external data file ;-)
String[] palettes = {
  "-1117720,-13683658,-8410437,-9998215,-1849945,-5517090,-4250587,-14178341,-5804972,-3498634", 
  "-67879,-9633503,-8858441,-144382,-4996094,-16604779,-588031", 
  "-1978728,-724510,-15131349,-13932461,-4741770,-9232823,-3195858,-8989771,-2850983,-10314372"
};
color[] colorPalette;

// the main PBox2D object in which all the physics-based stuff is happening
PBox2D box2d;
// list to hold all the custom shapes (circles, polygons)
ArrayList<CustomShape> polygons = new ArrayList<CustomShape>();
ArrayList<UserShape> userpolys = new ArrayList<UserShape>();

void setup() {
  // it's possible to customize this, for example 1920x1080
  size(1280, 720, OPENGL);
  context = new SimpleOpenNI(this);
  
  // enable skeleton generation for all joints
  println("Setting up skeletal tracking");
  context.enableDepth();
  //context.enableRGB();
  context.enableScene();
  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  println("Done with skeletal tracking");

  // initialize SimpleOpenNI object
  if (!context.enableScene()) { 
    // if context.enableScene() returns false
    // then the Kinect is not working correctly
    // make sure the green light is blinking
    println("Kinect not connected!"); 
    exit();
  } else {
    // mirror the image to be more intuitive
    context.setMirror(true);
    // calculate the reScale value
    // currently it's rescaled to fill the complete width (cuts of top-bottom)
    // it's also possible to fill the complete height (leaves empty sides)
    reScale = (float) width / kinectWidth;
    // create a smaller blob image for speed and efficiency
    blobs = createImage(kinectWidth/3, kinectHeight/3, RGB);
    // initialize blob detection object to the blob image dimensions
    theBlobDetection = new BlobDetection(blobs.width, blobs.height);
    theBlobDetection.setThreshold(0.2);
    // initialize ToxiclibsSupport object
    gfx = new ToxiclibsSupport(this);
    // setup box2d, create world, set gravity
    box2d = new PBox2D(this);
    box2d.createWorld();
    box2d.setGravity(0, 20);
    // set random colors (background, blob)
    setRandomColors(1);
  }
}

void draw() {
  background(bgColor);
  // update the SimpleOpenNI object
  context.update();
  // put the image into a PImage
  cam = context.sceneImage().get();
  int[] map = context.sceneMap();
  int[] depth = context.depthMap();
//  for (int y=0; y<kinectHeight; y+=3) {
//    for (int x=0; x<kinectWidth; x+=3) {
//      if (noise(x,y) > 0.9) {
//        if (map[x+y*kinectWidth] != 0 && userpolys.size() < 1000) {
//          userpolys.add(new UserShape(x, y, 10));
//        }
//      }
//    }
//  }
  if (frameCount % 1 == 0) {
    for (int i=0; i<200; i++) {
      int x = int(random(0, kinectWidth));
      int y = int(random(0, kinectHeight));
      int loc = x+y*kinectWidth;
      if (map[loc] != 0 && userpolys.size() < 500) {
        float size = 20-depth[loc]/250;
        float randomsize = random(10,20);
        
        userpolys.add(new UserShape(x, y, size, map[loc]));
      }
    }
  }
  // copy the image into the smaller blob image
  //blobs.copy(cam, 0, 0, cam.width, cam.height, 0, 0, blobs.width, blobs.height);
  // blur the blob image
  //blobs.filter(BLUR, 1);
  // detect the blobs
  //theBlobDetection.computeBlobs(blobs.pixels);
  // initialize a new polygon
  //poly = new PolygonBlob();
  // create the polygon from the blobs (custom functionality, see class)
  //poly.createPolygon();
  // create the box2d body from the polygon
  //poly.createBody();
  // update and draw everything (see method)
  updateAndDrawBox2D();
  // destroy the person's body (important!)
  //poly.destroyBody();
  // set the colors randomly every 240th frame
  //setRandomColors(240);
  //*/
    // draw the skeleton if it's available
  int[] userList = context.getUsers();
  for(int i=0;i<userList.length;i++)
  {
    if(context.isTrackingSkeleton(userList[i]))
      drawSkeleton(userList[i]);
  }    
}

void updateAndDrawBox2D() {
  // if frameRate is sufficient, add a polygon and a circle with a random radius
  if (frameRate > 29 && polygons.size() < MAX_SHAPES) {
    polygons.add(new CustomShape(kinectWidth/2, height+50, -1));
    polygons.add(new CustomShape(kinectWidth/2, height+50, random(2.5, 20)));
  }
  int start = millis();
  // take one step in the box2d physics world
  box2d.step();
  int end = millis();
  //println("time in box2d update: "+(end-start));

  // center and reScale from Kinect to custom dimensions
  translate(0, (height-kinectHeight*reScale)/2);
  scale(reScale);

  // display the person's polygon  
  //noStroke();
  //fill(blobColor);
  //gfx.polygon2D(poly);


  start = millis();
  // display all the shapes (circles, polygons)
  // go backwards to allow removal of shapes
  for (int i=polygons.size()-1; i>=0; i--) {
    CustomShape cs = polygons.get(i);
    // if the shape is off-screen remove it (see class for more info)
    if (cs.done()) {
      polygons.remove(i);
    // otherwise update (keep shape outside person) and display (circle or polygon)
    } else {
      cs.update();
      cs.display();
    }
  }
  //println("time in drawing other shapes: "+(millis()-start));
  
  
  start = millis();
  // display all the shapes (circles, polygons)
  // go backwards to allow removal of shapes
  for (int i=userpolys.size()-1; i>=0; i--) {
    UserShape cs = userpolys.get(i);
    // if the shape is off-screen remove it (see class for more info)
    if (cs.done()) {
      userpolys.remove(i);
    // otherwise update (keep shape outside person) and display (circle or polygon)
    } else {
      cs.update();
      cs.display();
    }
  }
  //println("time in drawing polygons: "+(millis()-start));


}

// sets the colors every nth frame
void setRandomColors(int nthFrame) {
  if (frameCount % nthFrame == 0) {
    // turn a palette into a series of strings
    String[] paletteStrings = split(palettes[int(random(palettes.length))], ",");
    // turn strings into colors
    colorPalette = new color[paletteStrings.length];
    for (int i=0; i<paletteStrings.length; i++) {
      colorPalette[i] = int(paletteStrings[i]);
    }
    // set background color to first color from palette
    bgColor = colorPalette[0];
    // set blob color to second color from palette
    blobColor = colorPalette[1];
    // set all shape colors randomly
    for (CustomShape cs: polygons) { cs.col = getRandomColor(); }
  }
}

// returns a random color from the palette (excluding first aka background color)
color getRandomColor() {
  return colorPalette[int(random(1, colorPalette.length))];
}


// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  // to get the 3d joint data
  /*
  PVector jointPos = new PVector();
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,jointPos);
  println(jointPos);
  */
  
  PVector jointPos = new PVector();
  PVector screenPos = new PVector();
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_HAND,jointPos);
  context.convertRealWorldToProjective(jointPos, screenPos);
  //println(jointPos);
  fill(255, 0, 0, 255);
  noStroke();
  ellipse(screenPos.x, screenPos.y, 10, 10);
  
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_HAND,jointPos);
  context.convertRealWorldToProjective(jointPos, screenPos);
  println(jointPos);
  println(screenPos);
  fill(0,255, 0, 255);
  noStroke();
  ellipse(screenPos.x, screenPos.y, 10, 10);


  
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}


// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(int userId)
{
  println("onNewUser - userId: " + userId);
  println("  start pose detection");
  
  if(autoCalib)
    context.requestCalibrationSkeleton(userId,true);
  else    
    context.startPoseDetection("Psi",userId);
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
}

void onExitUser(int userId)
{
  println("onExitUser - userId: " + userId);
}

void onReEnterUser(int userId)
{
  println("onReEnterUser - userId: " + userId);
}

void onStartCalibration(int userId)
{
  println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
  println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);
  
  if (successfull) 
  { 
    println("  User calibrated !!!");
    context.startTrackingSkeleton(userId); 
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
    println("  Start pose detection");
    context.startPoseDetection("Psi",userId);
  }
}

void onStartPose(String pose,int userId)
{
  println("onStartPose - userId: " + userId + ", pose: " + pose);
  println(" stop pose detection");
  
  context.stopPoseDetection(userId); 
  context.requestCalibrationSkeleton(userId, true);
 
}

void onEndPose(String pose,int userId)
{
  println("onEndPose - userId: " + userId + ", pose: " + pose);
}


