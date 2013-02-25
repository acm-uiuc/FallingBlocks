class PhysicsSkeleton {
  
  Body rightHandBody;
  
  Body leftHandBody;
 
  PVector prevPositionR;
  PVector prevPositionL;
  
  public PhysicsSkeleton() {
    
    prevPositionL= new PVector();
    prevPositionR = new PVector();
    
    CircleShape cs = new CircleShape();
    cs.m_radius = box2d.scalarPixelsToWorld(5);
    // tweak the circle's fixture def a little bit
    FixtureDef fd = new FixtureDef();
    fd.shape = cs;
    fd.density = 1;
    fd.friction = 0.9901;
    fd.restitution = 0.3;
    Filter filter = new Filter();
    filter.categoryBits = USER_SHAPES;
    filter.maskBits = FALLING_SHAPES + GRAVITY_SHAPES;
    fd.filter = filter;
    
    BodyDef lbd = new BodyDef();
    lbd.type = BodyType.DYNAMIC;
    lbd.position.set(box2d.coordPixelsToWorld(new Vec2(0, 0)));
    
    BodyDef rbd = new BodyDef();
    rbd.type = BodyType.DYNAMIC;
    rbd.position.set(box2d.coordPixelsToWorld(new Vec2(0, 0)));
    
    leftHandBody = box2d.createBody(lbd);
    rightHandBody = box2d.createBody(rbd);
    leftHandBody.createFixture(fd);
    rightHandBody.createFixture(fd);
  }
  
  public void updateHands(float rX, float rY, float lX, float lY) {
   
    rightHandBody.setTransform(box2d.coordPixelsToWorld(new Vec2(rX, rY)), 0);
    leftHandBody.setTransform(box2d.coordPixelsToWorld(new Vec2(lX, lY)), 0);
   
    rightHandBody.setLinearVelocity(new Vec2(rX - prevPositionR.x, rY - prevPositionR.y));
    leftHandBody.setLinearVelocity(new Vec2(lX - prevPositionL.x, lY - prevPositionL.y));
    
    prevPositionR = new PVector(rX, rY); 
    prevPositionL = new PVector(lX, lY);
  }
}
