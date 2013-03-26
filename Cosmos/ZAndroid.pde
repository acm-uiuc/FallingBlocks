import android.view.MotionEvent;


//-------------------------------------------------------------------------------------
// This is the stock Android touch event 
boolean surfaceTouchEvent(MotionEvent event) {
  
  // extract the action code & the pointer ID
  int action = event.getAction();
  int code   = action & MotionEvent.ACTION_MASK;
  int index  = action >> MotionEvent.ACTION_POINTER_ID_SHIFT;

  float x = event.getX(index);
  float y = event.getY(index);
  int id  = event.getPointerId(index);

  // pass the events to the TouchProcessor
  if ( code == MotionEvent.ACTION_DOWN || code == MotionEvent.ACTION_POINTER_DOWN) {
    parseMotionEvent(event, -1);
  }
  else if (code == MotionEvent.ACTION_UP || code == MotionEvent.ACTION_POINTER_UP) {
    parseMotionEvent(event, id);
  }
  else if ( code == MotionEvent.ACTION_MOVE) {
    parseMotionEvent(event, -1);
  } 

  return super.surfaceTouchEvent(event);
}


void parseMotionEvent(MotionEvent event, int excludeid) {
  int numPointers = event.getPointerCount();
  ArrayList<Pointer> pointers = new ArrayList<Pointer>();
  for (int i=0; i < numPointers; i++) {
    int id = event.getPointerId(i);
    float x = event.getX(i);
    float y = event.getY(i);
    if (id != excludeid) pointers.add(new Pointer(id, new PVector(x,y)));
  }
  pointerManager.setPointers(pointers);
}
