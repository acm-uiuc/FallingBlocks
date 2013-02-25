final static int MAX_CIRCLES = 1000;




class UserManager {
  HashMap<Integer, UserInfo> usermap = new HashMap<Integer, UserInfo>();
  ArrayList<UserShape> userpolys = new ArrayList<UserShape>();

  public void update() {
    for (UserInfo info : usermap.values()) {
      info.update();
    }
    
    HashMap<Integer, UserInfo> scenetouser = makeSceneToUserMap();
    
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
  
  
  HashMap<Integer, UserInfo> makeSceneToUserMap() {
    HashMap<Integer, UserInfo> scenetouser = new HashMap<Integer, UserInfo>();
    for (UserInfo info : usermap.values()) {
      if (info.sceneid != 0)
        scenetouser.put(info.sceneid, info);
    }
  
    return scenetouser;
  }
  
  
  void newUser(int userId) {
    usermap.put(userId, new UserInfo(userId));
  }
  void exitUser(int userId) {
    usermap.remove(userId);
  }
  void lostUser(int userId) {
    usermap.remove(userId);
  }
  void reenterUser(int userId) {
    usermap.put(userId, new UserInfo(userId));
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


class UserInfo {
  int id;
  int sceneid;
  float width, lowx, highx;
  PVector lefthand = new PVector();
  PVector righthand = new PVector();
 
  public UserInfo(int id) {
    this.id = id;
  } 
 
  public void update() {
    updateHands();
    findSceneId();
  } 
  
  
  private void updateHands() {
    float lowx = 100000; //reallllyyy large
    float highx = 0;

    PVector jointPos = new PVector();
    context.getJointPositionSkeleton(id, SimpleOpenNI.SKEL_LEFT_HAND, jointPos);
    context.convertRealWorldToProjective(jointPos, lefthand);
    context.getJointPositionSkeleton(id, SimpleOpenNI.SKEL_RIGHT_HAND, jointPos);
    context.convertRealWorldToProjective(jointPos, righthand);
    
    lowx = Math.min(lowx, lefthand.x);
    highx = Math.max(highx, lefthand.x);
    lowx = Math.min(lowx, righthand.x);
    highx = Math.max(highx, righthand.x);
    
    this.width = highx-lowx;
    this.lowx = lowx;
    this.highx = highx;
  }

  private void findSceneId() {
    int[] map = context.sceneMap();
    
    int[] jointID = {
      SimpleOpenNI.SKEL_LEFT_HAND, 
      SimpleOpenNI.SKEL_RIGHT_HAND,
      SimpleOpenNI.SKEL_HEAD,
      SimpleOpenNI.SKEL_NECK,
      SimpleOpenNI.SKEL_LEFT_SHOULDER,
      SimpleOpenNI.SKEL_RIGHT_SHOULDER,
      SimpleOpenNI.SKEL_LEFT_ELBOW,
      SimpleOpenNI.SKEL_RIGHT_ELBOW,
      SimpleOpenNI.SKEL_TORSO,
    };
    int[] results = new int[jointID.length];
    
    
    PVector jointPos = new PVector();
    PVector screenPos = new PVector();

    for (int i=0; i<jointID.length; i++) {
      context.getJointPositionSkeleton(id, jointID[i], jointPos);
      context.convertRealWorldToProjective(jointPos, screenPos);
      if (isValidIndex(screenPos.x, screenPos.y)) {
        results[i] = map[kinectXYtoIndex(screenPos.x,screenPos.y)];
      }
    }
    
    sort(results);
    if (results[jointID.length/2] != 0) {
      this.sceneid = results[jointID.length/2];
    } else {
      println("=== Error! can't find sceneid!");
    }
    this.sceneid = id;
    
  }

  
}















int kinectXYtoIndex(int x, int y) {
  return x+y*kinectWidth;
}

boolean isValidIndex(float x, float y) {
  return (x >= 0 && x < kinectWidth && y >= 0 && y < kinectHeight); 
}
int kinectXYtoIndex(float x, float y) {
  return int(x)+int(y)*kinectWidth;
}
