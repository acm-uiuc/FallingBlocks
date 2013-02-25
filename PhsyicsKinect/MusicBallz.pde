class MusicBallz {
  ArrayList<CustomShape> polygons = new ArrayList<CustomShape>();
  int MAX_SHAPES = 30;
  int rownum = -1;

  
  public void update() {
    if (counter.frame == 0 && counter.beat == 0) {
      int balls = 7;
      rownum += 1;
      float ballspacing = kinectWidth/(balls+2);
      for (int i=0; i<balls; i++) {
        if (polygons.size() < MAX_SHAPES) {
          polygons.add(new CustomShape(ballspacing*(i+1), -50, 13, i, rownum));
        }
      }
    }
  }
  
  
  
  public void applyRadialGravity(float x, float y, float g) {
    println("USER GRAVITY NUMSHAPES: "+polygons.size()+ " AT "+x+", "+y);
    Vec2 gravcenter = box2d.coordPixelsToWorld(x,y);
    for (CustomShape shape : polygons) {
      Vec2 shapecenter = shape.body.getPosition();
      Vec2 diff = gravcenter.sub(shapecenter);
      float dist = diff.lengthSquared();
      dist = max(dist, 30);
      diff.normalize();
      Vec2 results = diff.mul( g / dist );
      shape.body.applyForce(results, shapecenter);
    }
  }
  
  
  
  
    
  public void draw() {
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
  }
  
}
