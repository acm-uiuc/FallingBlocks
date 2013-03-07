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
import java.util.LinkedList;
import java.util.*;
import java.util.concurrent.*;
import msafluid.*;

//CONTACT LISTENER



final static int USER_SHAPES = 1;
final static int FALLING_SHAPES = 2;
final static int USER_FIGURE_SHAPES = 4;
final static int GRAVITY_SHAPES = 8;

// declare SimpleOpenNI object
ContextWrapper context;
// ToxiclibsSupport for displaying polygons
ToxiclibsSupport gfx;

// osc interface
OscP5 oscP5;
// localhost - our connection to puredata
NetAddress pdAddress;

boolean autoCalib=true;


boolean USE_KINECT = true;


// PImage to hold incoming imagery and smaller one for blob detection
PImage cam, blobs;
// the kinect's dimensions to be used later on for calculations
int kinectWidth = 640;
int kinectHeight = 480;
// to center and rescale from 640x480 to higher custom resolutions
float reScale;


// the main PBox2D object in which all the physics-based stuff is happening
PBox2D box2d;
Counter counter = new Counter();
OSCThread oscthread = new OSCThread();
// list to hold all the custom shapes (circles, polygons)

ArrayList<Layer> layers = new ArrayList<Layer>();
UserManager usermanager = new UserManager(); 

void setup() {
  // it's possible to customize this, for example 1920x1080
  //size(800, 600, OPENGL);
  size(displayWidth, displayHeight, OPENGL);
  frameRate(60);
  
  if (USE_KINECT) {
    context = new ContextWrapper(new SimpleOpenNI(this));
  } else {
    new SimpleOpenNI(this);
    context = new ContextWrapper(null);
  }
  // enable skeleton generation for all joints
  println("Setting up skeletal tracking");
  context.enableDepth();
  //context.enableRGB();
  //context.enableScene();
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
    // initialize ToxiclibsSupport object
    // set random colors (background, blob)
  }
  
  
  gfx = new ToxiclibsSupport(this);
  // setup box2d, create world, set gravity
  box2d = new PBox2D(this);
  box2d.createWorld();
  box2d.setGravity(0, -35);
  box2d.listenForCollisions();
  
  /* set up layers */
  Layer gravity = new GravityLayer();
  gravity.setup();
  layers.add(gravity);
  Layer bouncy = new BouncyLayer();
  bouncy.setup();
  layers.add(bouncy);
  
  
  setupOSC();
}

void setupOSC() { 
  // start oscP5, telling it to listen for incoming messages at port 5001 */
  oscP5 = new OscP5(this,9124);
  // set the remote location to be the localhost on port 5001
  pdAddress = new NetAddress("127.0.0.1",9123);
  oscthread.start();
}
















void draw() {
  background(0);
  // update the SimpleOpenNI object
  context.update();
  counter.update();
  usermanager.update();
  
  updateAndDrawBox2D();

  sendFrame(); 
}

void updateAndDrawBox2D() {
  layers.get(0).update();
  
  int start = millis();
  // take one step in the box2d physics world
  box2d.step();
  int end = millis();
  println("time in box2d update: "+(end-start));

  // center and reScale from Kinect to custom dimensions
  translate(0, (height-kinectHeight*reScale)/2);
  scale(reScale);

  layers.get(0).draw();

}






class OSCThread extends Thread {
  public void run() {
    while(true) {
      try {
        
        for (Layer l : layers) {
          l.sendOSC();
        }
        usermanager.sendOSC();
        
      } catch (Exception e) {
        e.printStackTrace();
      }
      try { Thread.sleep(100L); } catch (Exception e) { } 
    }
  }
}


void sendMessage(OscMessage message) {
  oscP5.send(message, pdAddress);
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
    //sendMessage(myMessage); 
}




void beginContact(Contact c) {
  //println("Contact!"); 
  
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





class ContextWrapper {
  int[] scenemap = new int[kinectWidth*kinectHeight];
  int[] depthmap = new int[kinectWidth*kinectHeight];
  SimpleOpenNI context;
  
  public ContextWrapper(SimpleOpenNI context) {
    this.context = context;
  }
  
  boolean enableDepth() {
    if (context != null) return context.enableDepth();
    else return true;
  }
  boolean enableScene() {
    if (context != null) return context.enableScene();
    else return true;
  } 
  boolean enableUser(int x) {
    if (context != null) return context.enableUser(x);
    else return true;
  }
  
  void requestCalibrationSkeleton(int userId, boolean bool) {
    if (context != null) context.requestCalibrationSkeleton(userId,bool);
  }
  
  void startPoseDetection(String name, int userId) {
    if (context != null) context.startPoseDetection(name,userId);
  }
  
  void startTrackingSkeleton(int userId) {
    if (context != null) context.startTrackingSkeleton(userId);
  }
  
  void stopPoseDetection(int userId) {
    if (context != null) context.stopPoseDetection(userId);
  }  

  void setMirror(boolean mirrored) {
    if (context != null) context.setMirror(mirrored);
    else return;
  }  
  
  void getJointPositionSkeleton(int id, int joint, PVector jointPos) {
    if (context != null) context.getJointPositionSkeleton(id, joint, jointPos);
  }
  
  void convertRealWorldToProjective(PVector x, PVector y) {
    if (context != null) context.convertRealWorldToProjective(x, y);
  }
  
  void update() {
    if (context != null) context.update();
  }
  
  public PImage sceneImage() {
    if (context != null) return context.sceneImage();
    else return new PImage();
  }
  
  public int[] sceneMap() {
    if (context != null) return context.sceneMap();
    return scenemap;
  }
  public int[] depthMap() {
    if (context != null) return context.depthMap();
    return depthmap;
  }
}



