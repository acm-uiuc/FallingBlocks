
class GravityShapes {
  PGraphics p;
  ArrayList<GravityShape> gravityshapes = new ArrayList<GravityShape>();
  int maxshapesperbeat = 1;
  int MAX_SHAPES = 50;
  int shapecounter = 0;
  
  
  void setup() {
    //p = createGraphics(width, height);
    
  }
  
  void update() {
    synchronized(gravityshapes) {
      if (counter.frame == 0) {
        if (gravityshapes.size() < MAX_SHAPES) {
          gravityshapes.add(new GravityShape(random(0, kinectWidth), 0, 3, shapecounter));
          shapecounter += 1;
        }
      }
  
      
      for (UserInfo info : usermanager.usermap.values()) {
        if (Float.isNaN(info.lefthand.x) == false) {
          applyRadialGravity(info.lefthand.x, info.lefthand.y, 10000);
        }
        if (Float.isNaN(info.righthand.x) == false) {
          applyRadialGravity(info.righthand.x, info.righthand.y, 10000);
        }
      }
      
      if (USE_KINECT == false) {
        applyRadialGravity(mouseX*kinectWidth/float(width), mouseY*kinectHeight/float(height), 10000);
      }
      
      for (GravityShape g : gravityshapes) {
        Vec2 pos = box2d.getBodyPixelCoord(g.body);
        applyRadialGravity(pos.x, pos.y, 100);
      }
      println("Num asteroids: "+gravityshapes.size());
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
      dist = max(dist, 20);
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
    println("Sending out "+clonedshapes.size()+" messages");
    for (GravityShape shape : clonedshapes) {
      Vec2 pos = box2d.getBodyPixelCoord(shape.body);
   
      OscMessage msg = new OscMessage("/asteroid"); // "/collision 3 1.3 302, 400"
      msg.add(shape.id); // add an int to the osc message
      msg.add(pos.x);
      msg.add(pos.y);
      msg.add(shape.curvature);
      msg.add(shape.speed);
      sendMessage(msg);
    }

  }
  
}


// usually one would probably make a generic Shape class and subclass different types (circle, polygon), but that
// would mean at least 3 instead of 1 class, so for this tutorial it's a combi-class CustomShape for all types of shapes
// to save some space and keep the code as concise as possible I took a few shortcuts to prevent repeating the same code


color[] gravitycolors = {
  #557766,
};


int MAX_PATH = 10;
class GravityShape {
  // to hold the box2d body
  Body body;
  color col;
  float r;
  int id;
  int framecount = 0;
  int lifetime = 1370;
  LinkedList<Vec2> path = new LinkedList<Vec2>();
  float curvature;
  float velx;
  float vely;
  float speed;
  float forcemag;
  float forcex;
  float forcey;

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


  // display the customShape
  void display() {
    framecount += 1;
    Vec2 pos = box2d.getBodyPixelCoord(body);
    path.add(pos);
    calculateCurve();
    calculateVelocityAndSpeed();
    calculateForce();
    
    drawTail();
    // get the pixel coordinates of the body
    float alpha = 150 - framecount * 150/lifetime;
    noStroke();
    fill(red(col),green(col),blue(col), alpha);
    // depending on the r this combi-code displays either a polygon or a circle
    ellipse(pos.x, pos.y, r*2, r*2);
    
    
    fill(255,0,0, 100);
    rect(300, 100+(id%50)*2, this.curvature*200, 2);
    fill(0, 255, 0, 100);
    rect(100, 100+(id%50)*2, this.speed*1, 2);
    fill(0, 255, 255, 100);
    rect(50, 100+(id%50)*2, this.forcemag*100, 2);

    
    while (path.size() > MAX_PATH) path.poll();
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
  }
  
  void calculateForce() {
    Vec2 force = body.m_force;
    this.forcex = force.x;
    this.forcey = force.y;
    this.forcemag = force.length();
  }
  
  void drawTail() {
    if (path.size() <= 0) return;
    float alpha = 150 - framecount * 150/lifetime;
    stroke(red(col),green(col),blue(col), alpha/2);
    strokeJoin(BEVEL);
    strokeCap(SQUARE);
    strokeWeight(r*3);
    noFill();
    beginShape();
    vertex(path.getFirst().x, path.getFirst().y); // the first control point
    for (Vec2 point : path) {
      vertex(point.x, point.y);
    }
    endShape();
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
}



class GravityUser {
  ArrayList<GUserShape> userpolys = new ArrayList<GUserShape>();
  int max_shapes = 7000;
  int numperframe = 300;

  public void update() {
    HashMap<Integer, UserInfo> scenetouser = usermanager.makeSceneToUserMap();
    
    cam = context.sceneImage().get();
    int[] map = context.sceneMap();
    int[] depth = context.depthMap();
    if (frameCount % 1 == 0) {
      for (int i=0; i<numperframe; i++) {
        int x = int(random(0, kinectWidth));
        int y = int(random(0, kinectHeight));
        int loc = kinectXYtoIndex(x,y);
        if (map[loc] != 0 && userpolys.size() < max_shapes) {
          float size = 20-depth[loc]/250;
          size = min(10, size);
          size = size / 3;
          
          //userpolys.add(new GUserShape(x, y, size, map[loc], scenetouser.get(map[loc])));
          userpolys.add(new GUserShape(x, y, size, map[loc]));
        }
      }
    }
    for (UserInfo info : usermanager.usermap.values()) {
      for (int i=0; i<10; i++) {
        float x = random(-5, 5) + info.lefthand.x;
        float y = random(-5, 5) + info.lefthand.y;
        userpolys.add(new GUserShape(x, y, 4, info.sceneid));
      }      
      for (int i=0; i<10; i++) {
        float x = random(-5, 5) + info.righthand.x;
        float y = random(-5, 5) + info.righthand.y;
        userpolys.add(new GUserShape(x, y, 4, info.sceneid));
      }
      
    }
   
    
  }
  
  
  
  
  public void draw() {
    long start = millis();
    // display all the shapes (circles, polygons)
    // go backwards to allow removal of shapes
    pushStyle();
    noStroke();
    rectMode(CENTER);
    for (int i=userpolys.size()-1; i>=0; i--) {
      GUserShape cs = userpolys.get(i);
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
    popStyle();
  }

}


class GUserShape {
  float x, y;
  float size;
  float lifetime;
  int userid;
  int maxlife = 30;
  
  public GUserShape(float x, float y, float size, int userid) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.userid = userid;
    this.lifetime = 0;
  }
  
  public boolean done() {
    if (lifetime > maxlife) return true;
    return false;
  }
  
  public void display() {
    lifetime += 1;
    fill(200,100*(1-lifetime/maxlife));
    rect(x,y,size,size);
  }
  public void update() {
    
  }
  
}



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


