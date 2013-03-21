// Kinect Physics Example by Amnon Owed (15/09/12)

// import libraries
import SimpleOpenNI.*; // kinect
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







int SHOW_BORDER = 0;



float KINECT_BORDER_TOP = -60;
float KINECT_VERT_SCALE = 1.57;
int SHOW_KINECT_DEBUG = 0;







// declare SimpleOpenNI object
ContextWrapper context;

// osc interface
OscP5 oscP5;
// localhost - our connection to puredata
NetAddress pdAddress;
NetAddress lightsAddress;

boolean autoCalib=true;


boolean USE_KINECT = false;
boolean SUPER_FULLSCREEEN = true;
int NUM_KINECTS = 1;

// PImage to hold incoming imagery and smaller one for blob detection
PImage cam, blobs;
// the kinect's dimensions to be used later on for calculations
int kinectWidth = 640*NUM_KINECTS;
int kinectHeight = 480;
// to center and rescale from 640x480 to higher custom resolutions
float reScaleX,reScaleY;
boolean takeScreenshot = false;
int autoScreenshotTime = 1000;

// the main PBox2D object in which all the physics-based stuff is happening
PBox2D box2d;
Counter counter = new Counter();
OSCThread oscthread = new OSCThread();
// list to hold all the custom shapes (circles, polygons)

ArrayList<Layer> layers = new ArrayList<Layer>();
UserManager usermanager = new UserManager();


/** #FULLSCREEN
public void init() { 
  if (SUPER_FULLSCREEEN) {
    frame.removeNotify(); 
    frame.setUndecorated(true); 
    frame.addNotify(); 
    frame.setLocation(1920, 0);
  }
  super.init();
}
**/

void setup() {
  // it's possible to customize this, for example 1920x1080
  //size(800, 600, OPENGL);
  //size(displayWidth, displayHeight, OPENGL);
  size(displayWidth, displayHeight, OPENGL);
  /** #FULLSCREEN
  if (SUPER_FULLSCREEEN) {
    size(1280*2, 720, OPENGL);
  } else {
    size(displayWidth, displayHeight, OPENGL);
  }
  **/
  frameRate(60);
  //smooth(8);
  
  
  if (USE_KINECT) {
    //context = new ContextWrapper(new SimpleOpenNI(0,this), new SimpleOpenNI(0, this));
    context = new ContextWrapper(new SimpleOpenNI(0,this));
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
    reScaleX = (float) width / kinectWidth;
    reScaleY = (float) height / kinectHeight;
    // initialize ToxiclibsSupport object
    // set random colors (background, blob)
  }
  
  
  // setup box2d, create world, set gravity
  box2d = new PBox2D(this);
  box2d.createWorld();
  box2d.setGravity(0, -35);
  box2d.listenForCollisions();
  
  /* set up layers */
  Layer gravity = new GravityLayer();
  gravity.setup();
  layers.add(gravity);
  
  
  /** #FULLSCREEN
  if (SUPER_FULLSCREEEN) {
    frame.setLocation(1920, 0);
    //frame.setLocation(0, 0);
  }
  **/
  
  setupOSC();
  context.start();
}

void setupOSC() { 
  // start oscP5, telling it to listen for incoming messages at port 5001 */
  oscP5 = new OscP5(this,9124);
  // set the remote location to be the localhost on port 5001
  pdAddress = new NetAddress("127.0.0.1",9123);
  lightsAddress = new NetAddress("127.0.0.1",9125);
  oscthread.start();
}
















void draw() {
  background(0);
  // update the SimpleOpenNI object
  //context.update();
  counter.update();
  usermanager.update();
  
  pushMatrix();
  updateAndDrawBox2D();
  popMatrix();
  
  sendFrame();
  if (SHOW_BORDER == 1) {
    noFill();
    stroke(255,0,0);
    strokeWeight(5);
    rect(5,5,width-10,height-10); 
  }
 //println("FPS: "+frameRate);
 if (takeScreenshot) 
   screenshot();
 if (autoScreenshotTime > 0 && frameCount % autoScreenshotTime == 0) {
   screenshot();
 }
 if (SHOW_KINECT_DEBUG == 1) {
   image(context.depthImage(),200,0);
 }
}

void updateAndDrawBox2D() {
  layers.get(0).update();
  
  int start = millis();
  // take one step in the box2d physics world
  box2d.step();
  int end = millis();
  //println("time in box2d update: "+(end-start));

  // center and reScale from Kinect to custom dimensions
  //translate(0, (height-kinectHeight*reScale)/2);
  //scale(reScaleX,reScaleY);

  layers.get(0).draw();

}




/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
  if(theOscMessage.checkAddrPattern("/set/float")==true) {
    String var = theOscMessage.get(0).stringValue();
    float value = 0;
    try {
      value = theOscMessage.get(1).floatValue();
    } catch (Exception e) {
      value = theOscMessage.get(1).intValue();
    }
    try {
      println("Trying to change: '"+var+"' to "+value);
      this.getClass().getDeclaredField(var).setFloat(this, value);
    } catch (Exception e) {
      e.printStackTrace();
    }    
  }
  if(theOscMessage.checkAddrPattern("/set/int")==true) {
    String var = theOscMessage.get(0).stringValue();
    int value = 0;
    try {
      value = (int)theOscMessage.get(1).floatValue();
    } catch (Exception e) {
      value = theOscMessage.get(1).intValue();
    }
    try {
      println("Trying to change: '"+var+"' to "+value);
      this.getClass().getDeclaredField(var).setInt(this, value);
    } catch (Exception e) {
      e.printStackTrace();
    }    
  } 
 
  if(theOscMessage.checkAddrPattern("/RESET")==true) {
    reset();
  }  

  if(theOscMessage.checkAddrPattern("/screenshot")==true) {
    triggerScreenshot();
  }      
  if(theOscMessage.checkAddrPattern("/autoscreenshot")==true) {
    try {
      int value = theOscMessage.get(0).intValue();
      autoScreenshotTime = value;
    } catch (Exception e) {
      e.printStackTrace();
    }
  } 
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
  oscP5.send(message, lightsAddress);
  
}





void reset() {
  for (Layer l : layers) {
    l.reset();
  }
}

float randomint = random(1,1000000);
void screenshot() {
  saveFrame("sketchinstance-"+randomint+"-frame-######.png");
  println("Saving frame");  
  takeScreenshot = false;
}
void triggerScreenshot() {
  takeScreenshot = true;
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












class ContextWrapper {
  int[] scenemap = new int[kinectWidth*kinectHeight];
  int[] depthmap = new int[kinectWidth*kinectHeight];
  SimpleOpenNI context;
  SimpleOpenNI context2;
  
  
  Thread runthread = new Thread() {
    public void run() {
      while(true) {
        update();
        
        try { Thread.sleep(33); } catch (Exception e) {};
      }
    }
  };
  
  public ContextWrapper(SimpleOpenNI context) {
    this.context = context;
  }
  public ContextWrapper(SimpleOpenNI context, SimpleOpenNI context2) {
    this.context = context;
    this.context2 = context2;
  }
  
  void start()  {
    runthread.start();
  }
  
  boolean enableDepth() {
    if (context != null) context.enableDepth();
    if (context2 != null) context2.enableDepth();
    return true;
  }
  boolean enableScene() {
    if (context != null) context.enableScene();
    if (context2 != null) context2.enableScene();
    return true;
  } 
  boolean enableUser(int x) {
    if (context != null) context.enableUser(x);
    if (context2 != null) context2.enableUser(x);
    return true;
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
    if (context2 != null) context2.setMirror(mirrored);
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
    if (context2 != null) context2.update();
    
    if (context != null && context2 != null) {
      int[] map1 = context.sceneMap();
      int[] map2 = context2.sceneMap();
      
      int halfwidth = kinectWidth/2;
      for (int y=0; y < kinectHeight; y++) {
        for (int x=0; x < halfwidth; x++) {
          //scenemap[kinectWidth*y + x] = map1[halfwidth*y + x];
        }
        for (int x=0; x < halfwidth; x++) {
          scenemap[kinectWidth*y + x + halfwidth] = map2[halfwidth*y + x];
        }       
      }
      
      map1 = context.depthMap();
      map2 = context2.depthMap();
      for (int y=0; y < kinectHeight; y++) {
        for (int x=0; x < halfwidth; x++) {
          //depthmap[kinectWidth*y + x] = map1[halfwidth*y + x];
        }
        for (int x=0; x < halfwidth; x++) {
          depthmap[kinectWidth*y + x + halfwidth] = map2[halfwidth*y + x];
        }       
      }
    } else if (context != null) {
      scenemap = context.sceneMap();
      depthmap = context.depthMap();
    }
  }
  
  public PImage sceneImage() {
    if (context != null) return context.sceneImage();
    else return new PImage();
  }
  public PImage depthImage() {
    if (context != null) return context.depthImage();
    else return new PImage();
  }
  
  public int[] sceneMap() {
    //if (context != null) return context.sceneMap();
    return scenemap;
  }
  public int[] depthMap() {
    //if (context != null) return context.depthMap();
    return depthmap;
  }
}



