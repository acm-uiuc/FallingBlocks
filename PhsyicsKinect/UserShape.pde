// usually one would probably make a generic Shape class and subclass different types (circle, polygon), but that
// would mean at least 3 instead of 1 class, so for this tutorial it's a combi-class CustomShape for all types of shapes
// to save some space and keep the code as concise as possible I took a few shortcuts to prevent repeating the same code


color[] usercolors = {
  #ff2288,
  #22ff88,
  #88ff22,
  #ff8822,
  #88ff22,
  #2288ff,
};



class UserShape {
  // to hold the box2d body
  Body body;
  boolean dead = false;
  
  Vec2 pos;
  // to hold the Toxiclibs polygon shape
  color col;
  // radius (also used to distinguish between circles and polygons in this combi-class
  float r;
  int framecount = 0;
  int type = 0;
  int lifetime = 10;
  UserInfo user;

  UserShape(float x, float y, float r, int type, UserInfo user) {
    this.r = r;
    this.user = user;
    this.type = type;
    // create a body (polygon or circle based on the r)
    makeBody(x, y);
    // get a random color
    col = usercolors[type%usercolors.length];
  }

  void makeBody(float x, float y) {
    // define a dynamic body positioned at xy in box2d world coordinates,
    // create it and set the initial values for this box2d body's speed and angle
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    body = box2d.createBody(bd);
    //body.setLinearVelocity(new Vec2(random(-8, 8), random(2, 8)));
    //body.setAngularVelocity(random(-5, 5));
    body.setLinearVelocity(new Vec2(0, 20));
    body.setAngularVelocity(0);
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
    filter.categoryBits = USER_SHAPES;
    filter.maskBits = FALLING_SHAPES;
    fd.filter = filter;
    // create the fixture from the shape's fixture def (deflect things based on the actual circle shape)
    body.createFixture(fd);
    
  }

  // method to loosely move shapes outside a person's polygon
  // (alternatively you could allow or remove shapes inside a person's polygon)
  void update() {
    /*
    // get the screen position from this shape (circle of polygon)
    Vec2 posScreen = box2d.getBodyPixelCoord(body);
    // turn it into a toxiclibs Vec2D
    Vec2D toxiScreen = new Vec2D(posScreen.x, posScreen.y);
    // check if this shape's position is inside the person's polygon
    boolean inBody = false; //poly.containsPoint(toxiScreen);
    // if a shape is inside the person
    if (inBody) {
      // find the closest point on the polygon to the current position
      Vec2D closestPoint = toxiScreen;
      float closestDistance = 9999999;
      for (Vec2D v : poly.vertices) {
        float distance = v.distanceTo(toxiScreen);
        if (distance < closestDistance) {
          closestDistance = distance;
          closestPoint = v;
        }
      }
      // create a box2d position from the closest point on the polygon
      Vec2 contourPos = new Vec2(closestPoint.x, closestPoint.y);
      Vec2 posWorld = box2d.coordPixelsToWorld(contourPos);
      float angle = body.getAngle();
      // set the box2d body's position of this CustomShape to the new position (use the current angle)
      body.setTransform(posWorld, angle);
    }
    */
  }

  // display the customShape
  void display() {
    framecount += 1;
    // get the pixel coordinates of the body
    if (!dead) pos = box2d.getBodyPixelCoord(body);
    float alpha = 150 - framecount * 150/lifetime;
    noStroke();
    fill(red(col),green(col),blue(col), alpha);
    // depending on the r this combi-code displays either a polygon or a circle
    ellipse(pos.x, pos.y, r*2, r*2);
    //if (user != null) newr = newr * (1 + (Math.abs(((pos.x - user.lowx) / width + counter.measurearc))-0.5)*2.0 ) ;
    //newr = newr * (1+counter.measurearc*0.5);
    //fill(red(col),green(col),blue(col), alpha / 2);
    //fill(255*(counter.measurearc), alpha / 2);
    //ellipse(pos.x, pos.y, r, r);
    
  }

  // if the shape moves off-screen, destroy the box2d body (important!)
  // and return true (which will lead to the removal of this CustomShape object)
  boolean done() {
    if (framecount > lifetime/2 && dead == false) {
      box2d.destroyBody(body);
      dead = true;
      return false;
    } else  if (framecount > lifetime) {
      return true;
    }
    return false;
  }
}
