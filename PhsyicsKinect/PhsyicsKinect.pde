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
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.collision.Manifold;
import java.util.Collections;
import oscP5.*; // osc
import netP5.*; // osc


//CONTACT LISTENER



final static int USER_SHAPES = 1;
final static int FALLING_SHAPES = 2;
final static int USER_FIGURE_SHAPES = 4;
final static int INTERACTION_SHAPES = 8;

// declare SimpleOpenNI object
SimpleOpenNI context;
// declare BlobDetection object
BlobDetection theBlobDetection;
// ToxiclibsSupport for displaying polygons
ToxiclibsSupport gfx;
// declare custom PolygonBlob object (see class for more info)
PolygonBlob poly;

// osc interface
OscP5 oscP5;
// localhost - our connection to puredata
NetAddress pdAddress;

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
MusicBallz musicbox = new MusicBallz();
UserManager usermanager = new UserManager();
// list to hold all the custom shapes (circles, polygons)
ArrayList<UserShape> userpolys = new ArrayList<UserShape>();

void setup() {
  // it's possible to customize this, for example 1920x1080
  size(1280, 720, OPENGL);
  frameRate(30);
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
    box2d.setGravity(0, -35);
    box2d.listenForCollisions();
    // set random colors (background, blob)
    setRandomColors(1);
  }
  setupOSC();
}

void setupOSC() { 
  // start oscP5, telling it to listen for incoming messages at port 5001 */
  oscP5 = new OscP5(this,9124);
  // set the remote location to be the localhost on port 5001
  pdAddress = new NetAddress("127.0.0.1",9123);
}
















void draw() {
  background(0);
  // update the SimpleOpenNI object
  context.update();
  counter.update();

  // put the image into a PImage
//  for (int y=0; y<kinectHeight; y+=3) {
//    for (int x=0; x<kinectWidth; x+=3) {
//      if (noise(x,y) > 0.9) {
//        if (map[x+y*kinectWidth] != 0 && userpolys.size() < 1000) {
//          userpolys.add(new UserShape(x, y, 10));
//        }
//      }
//    }
//  }
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
 sendFrame(); 
}

void updateAndDrawBox2D() {
  musicbox.update();
  usermanager.update();
  int start = millis();
  // take one step in the box2d physics world
  box2d.step();
  int end = millis();
  println("time in box2d update: "+(end-start));

  // center and reScale from Kinect to custom dimensions
  translate(0, (height-kinectHeight*reScale)/2);
  scale(reScale);

  // display the person's polygon  
  //noStroke();
  //fill(blobColor);
  //gfx.polygon2D(poly);


  start = millis();
  musicbox.draw();
  
  //println("time in drawing other shapes: "+(millis()-start));
  
  
  usermanager.draw();

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
  }
}

// returns a random color from the palette (excluding first aka background color)
//color getRandomColor() {
//  return colorPalette[int(random(1, colorPalette.length))];
//}


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
  //println(jointPos);
  //println(screenPos);
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
    
  usermanager.newUser(userId);
    
  
  OscMessage myMessage = new OscMessage("/user/entered");
  myMessage.add(userId);  
  sendMessage(myMessage); 
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
  usermanager.lostUser(userId);
  
  OscMessage myMessage = new OscMessage("/user/lost");
  myMessage.add(userId);  
  sendMessage(myMessage); 

}

void onExitUser(int userId)
{
  println("onExitUser - userId: " + userId);
  usermanager.exitUser(userId);

  
  OscMessage myMessage = new OscMessage("/user/exit");
  myMessage.add(userId);  
  sendMessage(myMessage); }

void onReEnterUser(int userId)
{
  println("onReEnterUser - userId: " + userId);
  usermanager.reenterUser(userId);
  
  OscMessage myMessage = new OscMessage("/user/reenter");
  myMessage.add(userId);  
  sendMessage(myMessage); }

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


void sendFrame() {
    OscMessage myMessage = new OscMessage("/frame");
   
    myMessage.add(frameCount); // add an int to the osc message   
    // send the message
    sendMessage(myMessage); 
}

void sendMessage(OscMessage message) {
  oscP5.send(message, pdAddress);
}



void beginContact(Contact c) {
  println("Contact!"); 
  
  Vec2 posBody1 = box2d.getBodyPixelCoord(c.getFixtureA().m_body);
  Vec2 posBody2 = box2d.getBodyPixelCoord(c.getFixtureB().m_body);
  
  Vec2 velBody1 = c.getFixtureA().m_body.m_linearVelocity;
  Vec2 velBody2 = c.getFixtureB().m_body.m_linearVelocity;
  Vec2 velDiff = velBody1.sub(velBody2);
  
  if (velDiff.length() < 15.01f) return; // no point here.
  
  Object obj1 = c.getFixtureA().m_body.m_userData;
  Object obj2 = c.getFixtureB().m_body.m_userData;
  if (obj1 instanceof CustomShape) {
    CustomShape shape = (CustomShape)obj1;
    shape.hitframe = frameCount;
    // create an osc message
    OscMessage myMessage = new OscMessage("/collision");
   
    myMessage.add(shape.id); // add an int to the osc message
    myMessage.add(velDiff.length()); // add an int to the osc message
    myMessage.add(shape.groupid); // add an int to the osc message
    myMessage.add(posBody1.x); // add an int to the osc message
    myMessage.add(posBody1.y); // add an int to the osc message
   
    // send the message
    sendMessage(myMessage); 
  } 
  if (obj2 instanceof CustomShape) {
    CustomShape shape = (CustomShape)obj2;
    shape.hitframe = frameCount;
    // create an osc message
    OscMessage myMessage = new OscMessage("/collision"); // "/collision 3 1.3 302, 400"
   
    myMessage.add(shape.id); // add an int to the osc message
    myMessage.add(velDiff.length()); // add an int to the osc message
    myMessage.add(shape.groupid); // add an int to the osc message
    myMessage.add(posBody2.x); // add an int to the osc message
    myMessage.add(posBody2.y); // add an int to the osc message
   
    // send the message
    sendMessage(myMessage); 
  }  

}



