// Kinect Physics Example by Amnon Owed (15/09/12)

// import libraries
import pbox2d.*; // shiffman's jbox2d helper library
import org.jbox2d.collision.shapes.*; // jbox2d
import org.jbox2d.common.*; // jbox2d
import org.jbox2d.dynamics.*; // jbox2d
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.collision.Manifold;
import java.util.Collections;
import oscP5.*; // osc
import netP5.*; // osc
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
boolean USE_OSC = false;






// declare SimpleOpenNI object

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
int autoScreenshotTime = -1;

// the main PBox2D object in which all the physics-based stuff is happening
PBox2D box2d;
OSCThread oscthread = new OSCThread();
PointerManager pointerManager = new PointerManager();
// list to hold all the custom shapes (circles, polygons)

ArrayList<Layer> layers = new ArrayList<Layer>();

/**
This is Cosmos.
**/

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
  
  
  reScaleX = (float) width / kinectWidth;
  reScaleY = (float) height / kinectHeight;
  
  // setup box2d, create world, set gravity
  box2d = new PBox2D(this);
  box2d.createWorld();
  box2d.setGravity(0, -35);
  //box2d.listenForCollisions();
  
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
  for (SetupRunnable s : setupRunnables) {
    s.run();
  }
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
  
  pushMatrix();
  updateAndDrawBox2D();
  popMatrix();
  
  /*
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
 */
}

void updateAndDrawBox2D() {
  int start = millis();
  layers.get(0).update();
  int end = millis();
  println("time in asteroid update: "+(end-start));

  start = millis();
  // take one step in the box2d physics world
  box2d.step();
  end = millis();
  println("time in box2d update: "+(end-start));

  // center and reScale from Kinect to custom dimensions
  //translate(0, (height-kinectHeight*reScale)/2);
  //scale(reScaleX,reScaleY);
  
  start = millis();
  layers.get(0).draw();
  end = millis();
  println("time in draw: "+(end-start));
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
    while(USE_OSC) {
      try {
        
        for (Layer l : layers) {
          l.sendOSC();
        }
        
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
































void sendFrame() {
    OscMessage myMessage = new OscMessage("/frame");
   
    myMessage.add(frameCount); // add an int to the osc message   
    // send the message
    //sendMessage(myMessage); 
}



float MAX_GRAV_FORCE = 45;
float HAND_FORCE = 32500;
float BALL_FORCE = 200;
float BALL_SIZE = 4.6;
float BALL_VIZ_SIZE = 1.5;
float BALL_ALPHA = 200;
int MAX_TRAIL_LENGTH = 17;

int PARTICLES_PER_FRAME = 1000;
float PARTICLE_SCALE = 2.2;
float HAND_SCALE = 1.5;


int MAX_PARTICLES = 48;
int PARTICLE_LIFE = 300;
int ONSCREEN_SCALE = 0;

boolean NO_USER_VISUAL = true;


class GravityShapes {
  PGraphics p;
  ArrayList<GravityShape> gravityshapes = new ArrayList<GravityShape>();
  int maxshapesperbeat = 1;
  int shapecounter = 0;
  
  
  void setup() {
    //p = createGraphics(width, height);
    centerkinect = new b2Vec2(width/2, height/2);
  }
  
  void reset() {
    synchronized(gravityshapes) {
      for (GravityShape g : gravityshapes) {
        g.kill();
      }
      gravityshapes.clear();
    }
  }
  
  void update() {
    synchronized(gravityshapes) {
      if (frameCount % 30 == 0) {
        if (gravityshapes.size() < MAX_PARTICLES) {
          gravityshapes.add(new GravityShape(random(0, width), 0, BALL_SIZE, shapecounter));
          shapecounter += 1;
        }
      }
        
      if (USE_KINECT == false) {
        //applyRadialGravity(mouseX*kinectWidth/float(width), mouseY*kinectHeight/float(height), 10000);
        for (Pointer p : pointerManager.getPointers()) {
          applyRadialGravity(p.pos.x, p.pos.y, HAND_FORCE);
        }
      }
      
      for (GravityShape g : gravityshapes) {
        b2Vec2 pos = box2d.getBodyPixelCoord(g.body);
        applyRadialGravity(pos.x, pos.y, BALL_FORCE);
      }
      //println("Num asteroids: "+gravityshapes.size());
      
      for (GravityShape g : gravityshapes) {
        g.update();
      }
    }
  }
  
  
  public void antigravity() {
    for (GravityShape shape : gravityshapes) {
      shape.body.applyForce(new b2Vec2(0, 35), shape.body.getPosition());
    }
  }
  
  public void applyRadialGravity(float x, float y, float g) {
    //println("USER GRAVITY NUMSHAPES: "+gravityshapes.size()+ " AT "+x+", "+y);
    b2Vec2 gravcenter = box2d.coordPixelsToWorld(x,y);
    for (GravityShape shape : gravityshapes) {
      b2Vec2 shapecenter = shape.body.getPosition();
      b2Vec2 diff = gravcenter.sub(shapecenter);
      float dist = diff.lengthSquared();
      dist = max(dist, MAX_GRAV_FORCE);
      diff.normalize();
      b2Vec2 results = diff.mul( g / dist );
      shape.body.applyForce(results, shapecenter);
    }
  }

  
  
  void draw() {
    synchronized(gravityshapes) {
      for (int i=gravityshapes.size()-1; i>=0; i--) {
        GravityShape cs = gravityshapes.get(i);
        // if the shape is off-screen remove it (see class for more info)
        if (cs.done()) {
          gravityshapes.remove(i);
        // otherwise update (keep shape outside person) and display (circle or polygon)
        } else {
          //cs.update();
          cs.display();
        }
      }
    }
  }
  
  
  void sendOSC() {
    ArrayList<GravityShape> clonedshapes = null;
    synchronized(gravityshapes) {
      clonedshapes = (ArrayList<GravityShape>)gravityshapes.clone();
    }
    //println("Sending out "+clonedshapes.size()+" messages");
    for (GravityShape shape : clonedshapes) {
      b2Vec2 pos = box2d.getBodyPixelCoord(shape.body);
   
      OscMessage msg = new OscMessage("/asteroid"); // "/collision 3 1.3 302, 400"
      msg.add(shape.id); // add an int to the osc message
      msg.add(pos.x);
      msg.add(pos.y);
      msg.add(shape.curvature);
      msg.add(shape.forcemag);
      msg.add(shape.hue);
      msg.add(shape.closeness);
      msg.add(float(shape.framecount)/float(shape.lifetime));
      sendMessage(msg);
    }

  }
  
}

float scaleXKinectToScreen(float x) {
  return x/kinectWidth*width;
}
float scaleYKinectToScreen(float y) {
  return (y+KINECT_BORDER_TOP)/kinectHeight*height*KINECT_VERT_SCALE;
}
  


// usually one would probably make a generic Shape class and subclass different types (circle, polygon), but that
// would mean at least 3 instead of 1 class, so for this tutorial it's a combi-class CustomShape for all types of shapes
// to save some space and keep the code as concise as possible I took a few shortcuts to prevent repeating the same code


color[] gravitycolors = {
  260, 350,
};

b2Vec2 centerkinect;

class GravityShape {
  // to hold the box2d body
  Body body;
  color col;
  float r;
  int id;
  int framecount = 0;
  int lifetime = PARTICLE_LIFE;
  var path = linkedList();
  float curvature;
  float velx;
  float vely;
  float speed;
  float forcemag;
  float forcex;
  float forcey;
  float hue;
  float closeness;

  GravityShape(float x, float y, float r, int id) {
    this.r = r;
    this.id = id;
    // create a body (polygon or circle based on the r)
    makeBody(x, y, random(-10, 10), -20);
    // get a random color

  }

  void makeBody(float x, float y, float vx, float vy) {
    // define a dynamic body positioned at xy in box2d world coordinates,
    // create it and set the initial values for this box2d body's speed and angle
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(new b2Vec2(x, y)));
    body = box2d.createBody(bd);
    //body.setLinearVelocity(new b2Vec2(random(-8, 8), random(2, 8)));
    //body.setAngularVelocity(random(-5, 5));
    body.setLinearVelocity(new b2Vec2(vx, vy));
    body.setAngularVelocity(5);
    MassData md = new MassData();
    body.getMassData(md);
    md.mass = 10f;
    body.setMassData(md);
    
    
    CircleShape cs = new CircleShape();
    cs.m_radius = box2d.scalarPixelsToWorld(r);
    // tweak the circle's fixture def a little bit
    FixtureDef fd = new FixtureDef();
    fd.shape = cs;
    fd.density = 1;
    fd.friction = 0.9901;
    fd.restitution = 0.3;
    Filter filter = new Filter();
    filter.categoryBits = GRAVITY_SHAPES;
    filter.maskBits = GRAVITY_SHAPES;
    fd.filter = filter;
    // create the fixture from the shape's fixture def (deflect things based on the actual circle shape)
    body.createFixture(fd);
    
  }
  
  
  void update() {
    calculateForce();
  }


  // display the customShape
  void display() {
    //framecount += 1;
    b2Vec2 pos = box2d.getBodyPixelCoord(body);
	node = linkedListNode(pos);
    path.add(node);
    //calculateCurve();
    //calculateVelocityAndSpeed();
    calculateCloseness();
    if (this.closeness < 1) {
      framecount += 1;
    } else {
      framecount += 1*ONSCREEN_SCALE;
    }
    
    // get the pixel coordinates of the body
    pushStyle();
    float alpha = BALL_ALPHA - framecount * BALL_ALPHA/lifetime;
    colorMode(HSB, 360, 100, 100);
    float hue = lerp(260, -10, forcemag/530);
    this.hue = hue;
    
    stroke(hue, 65, 75, alpha);
    drawTail();
    
    noStroke();
    //fill(hue, 65, 75, alpha);
    fill(hue, 65, 80, alpha);
    ellipse(pos.x, pos.y, r*2*BALL_VIZ_SIZE, r*2*BALL_VIZ_SIZE);
    
    /*
    fill(255,100,100, 100);
    rect(300, 100+(id%50)*2, (this.curvature+0.0)*200, 2);
    fill(100, 100, 100, 100);
    rect(100, 100+(id%50)*2, this.closeness*100, 2);
    fill(0, 100,100, 100);
    rect(50, 100+(id%50)*2, this.forcemag*1, 2);
    //*/
  
    popStyle();
    
    
    while (path.getSize() > MAX_TRAIL_LENGTH){
      path.del(path.getHead());
    }
  }
  
  void calculateCurve() {
    if (path.getSize() < 3) return;
    int size = path.getSize();
    b2Vec2 pt1 = path.get(size-1).key;
    b2Vec2 pt2 = path.get(size-2).key;
    b2Vec2 pt3 = path.get(size-3).key;
    float newcurve = (float)findCurvature(pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y);
    float avgr = 8;
    this.curvature = (this.curvature*avgr+newcurve)/(avgr+1);
  }
  
  void calculateVelocityAndSpeed() {
    if (path.getSize() < 2) return;
    int size = path.getSize();
    b2Vec2 pt1 = path.get(size-1).key;
    b2Vec2 pt2 = path.get(size-2).key;
    b2Vec2 vel = pt1.sub(pt2);
    this.velx = vel.x;
    this.vely = vel.y;
    this.speed = vel.length();
    
    addForce(pt1.x, pt1.y, this.velx/3, this.vely/3, 0);
  }
  
  void calculateForce() {
    b2Vec2 force = body.m_force;
    this.forcex = force.x;
    this.forcey = force.y;
    float newforce = force.length();
    float smooth = 3;
    this.forcemag = (this.forcemag*smooth+newforce)/(smooth+1);
  }
  
  void calculateCloseness() {
    b2Vec2 pt1 = path.get(path.getSize()-1);
    if (pt1.x > 0 && pt1.x < width && pt1.y > 0 && pt1.y < height) {
      this.closeness = 1;
    } else {
      this.closeness = (float)Math.pow(Math.min(1,float(width)/(pt1.sub(centerkinect).length())), 1.6);
      //UPDATE THIS CODE TODO TODO
    }
  }
  
  void drawTail() {
    if (path.getSize() <= 0) return;
    
    
    //float alpha = 150 - framecount * 150/lifetime;
    //stroke(red(col),green(col),blue(col), alpha/2);
    pushMatrix();
    strokeJoin(ROUND);
    strokeCap(ROUND);
    strokeWeight(r/2);
    noFill();
    beginShape(LINES);
    vertex(path.getHead().key.x, path.getHead().key.y); // the first control point
    for (var i = 0; i < path.getSize(); i++) {
      var point = path.get(i).key;
      vertex(point.x, point.y);
    }
    endShape();
    
    
//    strokeJoin(ROUND);
//    strokeCap(ROUND);
//    strokeWeight(r);
//    noFill();
//    beginShape();
//    Vec2 pvert = path.getFirst();
//    //curveVertex(path.getFirst().x, path.getFirst().y/scaleamount); // the first control point
//    for (Vec2 point : path) {
//      //curveVertex(point.x, point.y/scaleamount);
//      
//      bezier(pvert.x, pvert.y, pvert.x, pvert.y, point.x, point.y, point.x, point.y);
//      pvert = point;
//    }
//    endShape();
    
    popMatrix();
  }

  // if the shape moves off-screen, destroy the box2d body (important!)
  // and return true (which will lead to the removal of this CustomShape object)
  boolean done() {
    if (framecount > lifetime) {
      box2d.destroyBody(body);
      return true;
    }
    return false;
  }
  void kill() {
    box2d.destroyBody(body);
  }
}




final float FLUID_WIDTH = 120;
MSAFluidSolver2D fluidSolver;
float velScale = 0.0001;
ParticleSystem particles;

class GravityUser {
  //ArrayList<GUserShape> userpolys = new ArrayList<GUserShape>();
  
  int max_shapes = 7000;
  int numperframe = 300;
  boolean triggerReset = true;
  
  public void setup() {
    // create fluid and set options
    fluidSolver = new MSAFluidSolver2D((int)(FLUID_WIDTH), (int)(FLUID_WIDTH * height/width));
    fluidSolver.enableRGB(true).setFadeSpeed(0.02).setDeltaT(0.5).setVisc(0.0001);
  
    // create particles
    particles = new ParticleSystem();
  }
  
  void reset() {
    triggerReset = true;
  }
  
  void actualReset() {
    particles = new ParticleSystem();
    fluidSolver.reset();
    triggerReset = false;
  }

  public void update() {
    //right now, this is too much for most devices to handle.
    if (NO_USER_VISUAL) return;
    // update the fluid simulation
    fluidSolver.update();
    
    // draw particles
    createParticles();
    
//    for (UserInfo info : usermanager.usermap.values()) {
//      for (int i=0; i<10; i++) {
//        float x = random(-5, 5) + info.lefthand.x;
//        float y = random(-5, 5) + info.lefthand.y;
//        userpolys.add(new GUserShape(x, y, 4, info.sceneid));
//      }      
//      for (int i=0; i<10; i++) {
//        float x = random(-5, 5) + info.righthand.x;
//        float y = random(-5, 5) + info.righthand.y;
//        userpolys.add(new GUserShape(x, y, 4, info.sceneid));
//      } 
//    }
  }
  
  // look through the scene to create particles
  void createParticles() {
    /*
    int[] map = context.sceneMap();
    int[] depth = context.depthMap();
    if (frameCount % 1 == 0) {
      for (int i=0; i<PARTICLES_PER_FRAME; i++) {
        int x = int(random(0, kinectWidth));
        int y = int(random(0, kinectHeight));
        int loc = int(x+y*kinectWidth);
        if (map[loc] != 0) {
          float radius = ((5-(float(depth[loc])/1000))*PARTICLE_SCALE);   // originally : ((5-(float(depth[loc])/1000))*2)
          particles.addParticle(scaleXKinectToScreen(x), scaleYKinectToScreen(y), radius);
          
          // read fluid info and add to velocity
//          int fluidIndex = fluidSolver.getIndexForNormalizedPosition(x/kinectWidth, y/kinectHeight);
//          float fluidVX = fluidSolver.u[fluidIndex];
//          float fluidVY = fluidSolver.v[fluidIndex];
          
          //addColor(x/kinectWidth, y/kinectHeight, lerp(250, -20, ((dist(0,0,fluidVX, fluidVY)*20000)/360)));
          //addforce
        }
      }
    }

    
    for (UserInfo info : usermanager.usermap.values()) {
      for (int i=0; i<10; i++) {
        float x = random(-5, 5) + info.lefthand.x;
        float y = random(-5, 5) + info.lefthand.y;
        particles.addParticle(scaleXKinectToScreen(x), scaleYKinectToScreen(y), PARTICLE_SCALE*HAND_SCALE);
      }      
      for (int i=0; i<10; i++) {
        float x = random(-5, 5) + info.righthand.x;
        float y = random(-5, 5) + info.righthand.y;
        particles.addParticle(scaleXKinectToScreen(x), scaleYKinectToScreen(y), PARTICLE_SCALE*HAND_SCALE);
      } 
    }
    */ //TODO an alternate is needed
  }
  
  
  public void draw() {
    //right now, this is too much for most devices to handle.
    if (NO_USER_VISUAL) return;

    particles.updateAndDraw();
    if (triggerReset) {
      actualReset();
    }
  }
}


void addForce(float x, float y, float dx, float dy, float hue) {
  addForceAbs(x/float(width), y/float(height), dx/float(width), dy/float(height), hue);
}

void addForceAbs(float x, float y, float dx, float dy, float hue) {
    float speed = dx * dx  + dy * dy * float(height)/float(width);    // balance the x and y components of speed with the screen aspect ratio
    if(speed > 0) {
        if(x<0) x = 0; 
        else if(x>1) x = 1;
        if(y<0) y = 0; 
        else if(y>1) y = 1;

        float velocityMult = 30.0f;

        int index = fluidSolver.getIndexForNormalizedPosition(x, y);
        //println("Adding force at "+x+" and "+y+" at index: "+index);


        fluidSolver.uOld[index] += dx * velocityMult;
        fluidSolver.vOld[index] += dy * velocityMult;
        
        //particles.addParticle(x*width, y*height);
    }  
}




/** Calculation stuff **/ 

public static double findCurvature(double x1, double y1, double x2, double y2, double x3, double y3) {
  double angle1 = getAngle(x1,y1,x2,y2);
  double angle2 = getAngle(x2,y2,x3,y3);
  if (angle1 == 0.0f || angle2 == 0.0f) {
    return 0.0f;
  }    
  double result = angle1-angle2;
  if (result > Math.PI) {
    //System.out.println("Result too big! taking other atan2: "+result+" New: "+(2*Math.PI-result));

    result =  (2*Math.PI-result);
  }
  else if (result < -1*Math.PI) {
    //System.out.println("Result too small! taking other atan2: "+result+" New: "+(2*Math.PI+result));

    result =  (2*Math.PI+result);
  }

  //System.out.println("Curvature: "+result+" First Angle:"+angle1+" Second Angle: "+angle2);

  return result;

}
public static double getAngle(double x1, double y1, double x2, double y2) {
  return Math.atan2(x1-x2, y1-y2);
}


public class Layer {
  
  
  public void setup() {
    
  }
  
  public void update() {
    
  }
  
  public void draw() {
    
  }
  
  public void start() {
    
  }
  
  public void stop() {
    
  }
  
  public void sendOSC() {
    
  }
  
  public void reset() {
    
  }
  
}




public class GravityLayer extends Layer {
  GravityShapes gravityshapes = new GravityShapes();
  GravityUser user = new GravityUser();
  
  public void setup() {
    super.setup();
    gravityshapes.setup();
    user.setup();
  }
  
  public void update() {
    gravityshapes.update();
    user.update();
  }
  
  public void draw() {
    gravityshapes.draw();
    user.draw();
    //rect(5,5,width-10,height-10); 
  }
  
  public void sendOSC() {
    gravityshapes.sendOSC();
  }
  
  public void reset() {
    gravityshapes.reset();
    user.reset();
  }
}

/***********************************************************************
 
 Copyright (c) 2008, 2009, Memo Akten, www.memo.tv
 *** The Mega Super Awesome Visuals Company ***
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of MSA Visuals nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
 * ***********************************************************************/ 

class Particle {
    final static float MOMENTUM = 0.5;
    final static float FLUID_FORCE = 0.6;
    
    float x, y;
    float vx, vy;
    float radius;       // particle's size
    //float alpha;
    float mass;
    float age;
    float maxLife;

    void init(float x, float y, float radius) {
        this.x = x;
        this.y = y;
        vx = 0;
        vy = 0;
        this.radius = radius; // originally 5
        //alpha  = random(0.3, 1);
        mass = random(0.001, 0.01);
        age = 0;
        maxLife = 20;
        if (random(0, 20) <= 1) {
          maxLife = 100;
          mass = 0.2;
        }
    }


    void update() {
        // only update if particle is visible
        //if(alpha == 0) return;
        if(age >= maxLife) return;
        age += 1; // add one to the age every time until it gets to 20, then die

        // read fluid info and add to velocity
        int fluidIndex = fluidSolver.getIndexForNormalizedPosition(x / float(width), y / float(height) );
        vx = fluidSolver.u[fluidIndex] * width * mass * FLUID_FORCE + vx * MOMENTUM;
        vy = fluidSolver.v[fluidIndex] * height * mass * FLUID_FORCE + vy * MOMENTUM;

        // update position
        x += vx;
        y += vy;

//        // bounce of edges
//        if(x<0) {
//            x = 0;
//            vx *= -1;
//        }
//        else if(x > width) {
//            x = width;
//            vx *= -1;
//        }
//
//        if(y<0) {
//            y = 0;
//            vy *= -1;
//        }
//        else if(y > height) {
//            y = height;
//            vy *= -1;
//        }

        // hackish way to make particles glitter when the slow down a lot
        if(vx * vx + vy * vy < 1) {
            vx = random(-1, 1);
            vy = random(-1, 1);
        }

        // fade out a bit (and kill if alpha == 0);
        //alpha *= 0.998;
        //if(alpha < 0.01) alpha = 0;


    }


    void draw() {
      if (age >= maxLife) {
        return;  // don't draw it
      }
      //fill(255,255,255,alpha);
      fill(255, 255, 255, 180*(1-age/maxLife)); // make it fade out as it ages
      ellipse(x,y,radius,radius);
    }

    



}








/***********************************************************************
 
 Copyright (c) 2008, 2009, Memo Akten, www.memo.tv
 *** The Mega Super Awesome Visuals Company ***
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of MSA Visuals nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
 * ***********************************************************************/ 

class ParticleSystem {

    final static int maxParticles = 20000;
    int curIndex = 0;

    Particle[] particles;

    ParticleSystem() {
        particles = new Particle[maxParticles];
        for(int i=0; i<maxParticles; i++) particles[i] = new Particle();
        curIndex = 0;

//        posArray = BufferUtil.newFloatBuffer(maxParticles * 2 * 2);// 2 coordinates per point, 2 points per particle (current and previous)
//        colArray = BufferUtil.newFloatBuffer(maxParticles * 3 * 2);
    }


    void updateAndDraw(){
//        PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;         // processings opengl graphics object
//        GL gl = pgl.beginGL();                // JOGL's GL object
//
//        gl.glEnable( GL.GL_BLEND );             // enable blending
//        if(!drawFluid) fadeToColor(gl, 0, 0, 0, 0.05);
//
//        gl.glBlendFunc(GL.GL_ONE, GL.GL_ONE);  // additive blending (ignore alpha)
//        gl.glEnable(GL.GL_LINE_SMOOTH);        // make points round
//        gl.glLineWidth(1);


//        if(renderUsingVA) {
//            for(int i=0; i<maxParticles; i++) {
//                if(particles[i].alpha > 0) {
//                    particles[i].update();
//                    particles[i].updateVertexArrays(i, posArray, colArray);
//                }
//            }    
//            gl.glEnableClientState(GL.GL_VERTEX_ARRAY);
//            gl.glVertexPointer(2, GL.GL_FLOAT, 0, posArray);
//
//            gl.glEnableClientState(GL.GL_COLOR_ARRAY);
//            gl.glColorPointer(3, GL.GL_FLOAT, 0, colArray);
//
//            gl.glDrawArrays(GL.GL_LINES, 0, maxParticles * 2);
//        } 
//        else {
            //gl.glBegin(GL.GL_LINES);               // start drawing points
            pushStyle();
            //println("Drawing "+maxParticles+" particles");
            for(int i=0; i<maxParticles; i++) {
                //if(particles[i].alpha > 0) {
                    rectMode(RADIUS);
                    noStroke();
                    particles[i].update();
                    particles[i].draw();    // use oldschool renderng
                // }
            }
            popStyle();
            //gl.glEnd();
//        }

//        gl.glDisable(GL.GL_BLEND);
//        pgl.endGL();
    }


//    void addParticles(float x, float y, int count ){
//        for(int i=0; i<count; i++) addParticle(x + random(-15, 15), y + random(-15, 15));
//    }


    void addParticle(float x, float y, float radius) {
        //if (curIndex % 100 == 0) println("Added 100th particle at "+x+" and "+y+ " with radius "+radius);
        particles[curIndex].init(x, y, radius);
        curIndex++;
        if(curIndex >= maxParticles) curIndex = 0;
    }

}









class Pointer {
  PVector pos;
  int id;
  //ArrayList<PVector> history;
  
  Pointer(int id, PVector pos) {
    this.id = id;
    this.pos = pos;
    //history = new ArrayList<PVector>();
    //history.add(pos);
  }
  
  void update(PVector newpos) {
    
    
    this.pos = newpos;
    //history.add(newpos);
  }
  
}


interface PointerHandler {
  
  void onPointerAdded(Pointer p);
  
  void onPointerRemoved(Pointer p);
  
  void onPointerUpdated(Pointer p);
  
}


class PointerManager {
  ArrayList<PointerHandler> listeners;
  public void addListener(PointerHandler handler) {
    this.listeners.add(handler);
  }
  
  ArrayList<Pointer> pointers = new ArrayList<Pointer>();
  
  public void setPointers(ArrayList<Pointer> pointers) {
    this.pointers = pointers;
  }
    
  ArrayList<Pointer> getPointers() { 
    return this.pointers; 
  }

}

ArrayList<SetupRunnable> setupRunnables = new ArrayList<SetupRunnable>();
abstract class SetupRunnable {
  public SetupRunnable() {
    setupRunnables.add(this);
  }
  public abstract void run();
}




/** This code is only supposed to work in normal 'desktop' or 'java' mode **/

boolean click_only = true;

Pointer mouse = new Pointer(0, new PVector(mouseX, mouseY));
ArrayList<Pointer> mousepointers = new ArrayList<Pointer>();

SetupRunnable s = new SetupRunnable() {
  public void run() {
    if (click_only == false)
      mousepointers.add(mouse);
  }
};

void mouseMoved() {
  mouse.update(new PVector(mouseX, mouseY));
  pointerManager.setPointers(mousepointers);
}


void mouseDragged() {
  mouse.update(new PVector(mouseX, mouseY));
  pointerManager.setPointers(mousepointers);
}

void mousePressed() {
  if (click_only) {
    if( mousepointers.contains(mouse) == false) {
      mousepointers.add(mouse);
    }
  } 
}

void mouseReleased() {
  if (click_only) {
    mousepointers.remove(mouse);
  } 
}

