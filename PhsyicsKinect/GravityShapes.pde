float MAX_GRAV_FORCE = 35;
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

class GravityShapes {
  PGraphics p;
  ArrayList<GravityShape> gravityshapes = new ArrayList<GravityShape>();
  int maxshapesperbeat = 1;
  int shapecounter = 0;
  
  
  void setup() {
    //p = createGraphics(width, height);
    centerkinect = new Vec2(width/2, height/2);
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
      if (counter.frame == 0) {
        if (gravityshapes.size() < MAX_PARTICLES) {
          gravityshapes.add(new GravityShape(random(0, width), 0, BALL_SIZE, shapecounter));
          shapecounter += 1;
        }
      }
  
      
      for (UserInfo info : usermanager.usermap.values()) {
        if (Float.isNaN(info.lefthand.x) == false) {
          applyRadialGravity(scaleXKinectToScreen(info.lefthand.x), scaleYKinectToScreen(info.lefthand.y), HAND_FORCE);
        }
        if (Float.isNaN(info.righthand.x) == false) {
          applyRadialGravity(scaleXKinectToScreen(info.righthand.x), scaleYKinectToScreen(info.righthand.y), HAND_FORCE);
        }
      }
      
      if (USE_KINECT == false) {
        //applyRadialGravity(mouseX*kinectWidth/float(width), mouseY*kinectHeight/float(height), 10000);
        applyRadialGravity(mouseX, mouseY, HAND_FORCE);
      }
      
      for (GravityShape g : gravityshapes) {
        Vec2 pos = box2d.getBodyPixelCoord(g.body);
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
      shape.body.applyForce(new Vec2(0, 35), shape.body.getPosition());
    }
  }
  
  public void applyRadialGravity(float x, float y, float g) {
    //println("USER GRAVITY NUMSHAPES: "+gravityshapes.size()+ " AT "+x+", "+y);
    Vec2 gravcenter = box2d.coordPixelsToWorld(x,y);
    for (GravityShape shape : gravityshapes) {
      Vec2 shapecenter = shape.body.getPosition();
      Vec2 diff = gravcenter.sub(shapecenter);
      float dist = diff.lengthSquared();
      dist = max(dist, MAX_GRAV_FORCE);
      diff.normalize();
      Vec2 results = diff.mul( g / dist );
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
      Vec2 pos = box2d.getBodyPixelCoord(shape.body);
   
      OscMessage msg = new OscMessage("/asteroid"); // "/collision 3 1.3 302, 400"
      msg.add(shape.id); // add an int to the osc message
      msg.add(pos.x);
      msg.add(pos.y);
      msg.add(shape.curvature);
      msg.add(shape.forcemag);
      msg.add(shape.hue);
      msg.add(shape.closeness);
      msg.add(1-float(shape.framecount)/float(shape.lifetime));
      sendMessage(msg);
    }

  }
  
}

float scaleXKinectToScreen(float x) {
  return x/kinectWidth*width;
}
float scaleYKinectToScreen(float y) {
  return y/kinectHeight*height;
}
  


// usually one would probably make a generic Shape class and subclass different types (circle, polygon), but that
// would mean at least 3 instead of 1 class, so for this tutorial it's a combi-class CustomShape for all types of shapes
// to save some space and keep the code as concise as possible I took a few shortcuts to prevent repeating the same code


color[] gravitycolors = {
  260, 350,
};

Vec2 centerkinect;

class GravityShape {
  // to hold the box2d body
  Body body;
  color col;
  float r;
  int id;
  int framecount = 0;
  int lifetime = PARTICLE_LIFE;
  LinkedList<Vec2> path = new LinkedList<Vec2>();
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
    col = usercolors[int(random(0,gravitycolors.length))];
  }

  void makeBody(float x, float y, float vx, float vy) {
    // define a dynamic body positioned at xy in box2d world coordinates,
    // create it and set the initial values for this box2d body's speed and angle
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    body = box2d.createBody(bd);
    //body.setLinearVelocity(new Vec2(random(-8, 8), random(2, 8)));
    //body.setAngularVelocity(random(-5, 5));
    body.setLinearVelocity(new Vec2(vx, vy));
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
    Vec2 pos = box2d.getBodyPixelCoord(body);
    path.add(pos);
    calculateCurve();
    calculateVelocityAndSpeed();
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
    
    
    while (path.size() > MAX_TRAIL_LENGTH) path.poll();
  }
  
  void calculateCurve() {
    if (path.size() < 3) return;
    int size = path.size();
    Vec2 pt1 = path.get(size-1);
    Vec2 pt2 = path.get(size-2);
    Vec2 pt3 = path.get(size-3);
    float newcurve = (float)findCurvature(pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y);
    float avgr = 8;
    this.curvature = (this.curvature*avgr+newcurve)/(avgr+1);
  }
  
  void calculateVelocityAndSpeed() {
    if (path.size() < 2) return;
    int size = path.size();
    Vec2 pt1 = path.get(size-1);
    Vec2 pt2 = path.get(size-2);
    Vec2 vel = pt1.sub(pt2);
    this.velx = vel.x;
    this.vely = vel.y;
    this.speed = vel.length();
    
    addForce(pt1.x, pt1.y, this.velx/3, this.vely/3, 0);
  }
  
  void calculateForce() {
    Vec2 force = body.m_force;
    this.forcex = force.x;
    this.forcey = force.y;
    float newforce = force.length();
    float smooth = 3;
    this.forcemag = (this.forcemag*smooth+newforce)/(smooth+1);
  }
  
  void calculateCloseness() {
    Vec2 pt1 = path.get(path.size()-1);
    if (pt1.x > 0 && pt1.x < width && pt1.y > 0 && pt1.y < height) {
      this.closeness = 1;
    } else {
      this.closeness = (float)Math.pow(Math.min(1,float(width)/(pt1.sub(centerkinect).length())), 1.6);
      //UPDATE THIS CODE TODO TODO
    }
  }
  
  void drawTail() {
    if (path.size() <= 0) return;
    
    
    //float alpha = 150 - framecount * 150/lifetime;
    //stroke(red(col),green(col),blue(col), alpha/2);
    pushMatrix();
    strokeJoin(ROUND);
    strokeCap(ROUND);
    strokeWeight(r/2);
    noFill();
    beginShape();
    curveVertex(path.getFirst().x, path.getFirst().y); // the first control point
    for (Vec2 point : path) {
      curveVertex(point.x, point.y);
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
    int[] map = context.sceneMap();
    int[] depth = context.depthMap();
    if (frameCount % 1 == 0) {
      for (int i=0; i<PARTICLES_PER_FRAME; i++) {
        int x = int(random(0, kinectWidth));
        int y = int(random(0, kinectHeight));
        int loc = int(x+y*kinectWidth);
        if (map[loc] != 0) {
          float radius = ((5-(float(depth[loc])/1000))*PARTICLE_SCALE);   // originally : ((5-(float(depth[loc])/1000))*2)
          particles.addParticle((x/float(kinectWidth))*width, (y/float(kinectHeight))*height, radius);
          
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
        particles.addParticle((x/float(kinectWidth))*width, (y/float(kinectHeight))*height, PARTICLE_SCALE*HAND_SCALE);
      }      
      for (int i=0; i<10; i++) {
        float x = random(-5, 5) + info.righthand.x;
        float y = random(-5, 5) + info.righthand.y;
        particles.addParticle((x/float(kinectWidth))*width, (y/float(kinectHeight))*height, PARTICLE_SCALE*HAND_SCALE);
      } 
    }
  
  }
  
  
  public void draw() {
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


