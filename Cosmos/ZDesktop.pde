

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
