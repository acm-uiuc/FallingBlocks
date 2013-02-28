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





class BubbleUser {
  ArrayList<UserShape> userpolys = new ArrayList<UserShape>();

  public void update() {
    HashMap<Integer, UserInfo> scenetouser = usermanager.makeSceneToUserMap();
    
    cam = context.sceneImage().get();
    int[] map = context.sceneMap();
    int[] depth = context.depthMap();
    if (frameCount % 1 == 0) {
      for (int i=0; i<400; i++) {
        int x = int(random(0, kinectWidth));
        int y = int(random(0, kinectHeight));
        int loc = kinectXYtoIndex(x,y);
        if (map[loc] != 0 && userpolys.size() < MAX_CIRCLES) {
          float size = 20-depth[loc]/250;
          size = min(10, size);
          float randomsize = random(10,20);
          
          userpolys.add(new UserShape(x, y, size, map[loc], scenetouser.get(map[loc])));
        }
      }
    }
    
    
  }
  
  
  
  
  public void draw() {
    long start = millis();
    // display all the shapes (circles, polygons)
    // go backwards to allow removal of shapes
    for (int i=userpolys.size()-1; i>=0; i--) {
      UserShape cs = userpolys.get(i);
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
  }
  
}

