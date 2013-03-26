

class Pointer {
  PVector pos;
  int id;
  //ArrayList<PVector> history;
  
  Pointer(int id, PVector pos) {
    this.id = id;
    this.pos = pos;
    //history = new ArrayList<PVector>();
    //history.add(pos);
  }
  
  void update(PVector newpos) {
    
    
    this.pos = newpos;
    //history.add(newpos);
  }
  
}


interface PointerHandler {
  
  void onPointerAdded(Pointer p);
  
  void onPointerRemoved(Pointer p);
  
  void onPointerUpdated(Pointer p);
  
}


class PointerManager {
  ArrayList<PointerHandler> listeners;
  public void addListener(PointerHandler handler) {
    this.listeners.add(handler);
  }
  
    
  ArrayList<Pointer> getPointers() { 
    return new ArrayList<Pointer>(); 
  }

}


