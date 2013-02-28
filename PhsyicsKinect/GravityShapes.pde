
class GravityShapes {
  PGraphics p;
  ArrayList<GravityShape> gravityshapes = new ArrayList<GravityShape>();
  int maxshapesperbeat = 1;
  int MAX_SHAPES = 100;
  
  
  void setup() {
    //p = createGraphics(width, height);
    
  }
  
  void update() {
    
    if (counter.frame == 0) {
      if (gravityshapes.size() < MAX_SHAPES) {
        gravityshapes.add(new GravityShape(random(0, kinectWidth), 0, 3));
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

  }
  
  
  public void antigravity() {
    for (GravityShape shape : gravityshapes) {
      shape.body.applyForce(new Vec2(0, 35), shape.body.getPosition());
    }
  }
  
  public void applyRadialGravity(float x, float y, float g) {
    println("USER GRAVITY NUMSHAPES: "+gravityshapes.size()+ " AT "+x+", "+y);
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
  int framecount = 0;
  int lifetime = 1000;
  LinkedList<Vec2> path = new LinkedList<Vec2>();

  GravityShape(float x, float y, float r) {
    this.r = r;
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
    
    drawTail();
    // get the pixel coordinates of the body
    float alpha = 150 - framecount * 150/lifetime;
    noStroke();
    fill(red(col),green(col),blue(col), alpha);
    // depending on the r this combi-code displays either a polygon or a circle
    ellipse(pos.x, pos.y, r*2, r*2);
    
    while (path.size() > MAX_PATH) path.poll();
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

