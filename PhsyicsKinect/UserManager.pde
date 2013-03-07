final static int MAX_CIRCLES = 1000;



class UserManager {
  ConcurrentHashMap<Integer, UserInfo> usermap = new ConcurrentHashMap<Integer, UserInfo>();

  public void update() {
    for (UserInfo info : usermap.values()) {
      info.update();
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



  
  
  
  public void sendOSC() {
    for (UserInfo info : usermap.values()) {
      OscMessage msg = new OscMessage("/user"); // "/collision 3 1.3 302, 400"
      msg.add(info.id); // add an int to the osc message
      msg.add(info.lefthand.x);
      msg.add(info.lefthand.y);
      msg.add(info.righthand.x);
      msg.add(info.righthand.y);
      sendMessage(msg);
    }
  }
  
  
}


class UserInfo {
  int id;
  int sceneid;
  float width, lowx, highx;
  PVector lefthand = new PVector();
  PVector righthand = new PVector();
  
  PVector[] lastScreenPos = new PVector[15];
 
  public UserInfo(int id) {
    this.id = id;
  } 
 
  public void update() {
    updateHands();
    updateSkeleton();
    findSceneId();
  } 
  
  void updateSkeleton() {
  
    // to get the 3d joint data
    // from https://github.com/acm-uiuc/FallingBlocks/blob/master/PhsyicsKinect/PhsyicsKinect.pde
    
    // this array goes inside for some reason....
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
      SimpleOpenNI.SKEL_LEFT_HIP,
      SimpleOpenNI.SKEL_RIGHT_HIP,
      SimpleOpenNI.SKEL_LEFT_KNEE,
      SimpleOpenNI.SKEL_RIGHT_KNEE,
      SimpleOpenNI.SKEL_LEFT_FOOT,
      SimpleOpenNI.SKEL_RIGHT_FOOT,
    };
  
    for (int i=0; i<jointID.length; i++) {
  
      PVector jointPos = new PVector();  // 3D point
      PVector screenPos = new PVector();  // 2D point
      context.getJointPositionSkeleton(id, jointID[i], jointPos);
      context.convertRealWorldToProjective(jointPos, screenPos);
      
      if (lastScreenPos[i] == null) {    // if there's nothing in there   
        lastScreenPos[i] = screenPos;    // use the initial position
      }
      
      addForce(screenPos.x, screenPos.y, screenPos.x-lastScreenPos[i].x, screenPos.y-lastScreenPos[i].y, 0);
      lastScreenPos[i] = screenPos; // saving current value for next time (to remember the last point)
    }
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
