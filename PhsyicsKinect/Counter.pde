
static int framesPerBeat = 30;
static final int beatsPerMeasure = 4;
static final int measuresPerPhrase = 4;


class Counter {
  int frame;
  int beat;
  int measure;
  int phrase;
  
  float measureprogress;
  float measurearc;
  
  void update() {
    frame = frameCount % framesPerBeat;
    beat = (frameCount / framesPerBeat) % beatsPerMeasure;
    measure = (frameCount / (framesPerBeat*beatsPerMeasure)) % measuresPerPhrase;
    phrase = frameCount / (framesPerBeat*beatsPerMeasure*measuresPerPhrase);
    measureprogress =  float(frame + beat*framesPerBeat) / float(framesPerBeat*beatsPerMeasure);
    measurearc = abs(measureprogress - 0.5)*2.0;
    //println("Measure arc: "+measurearc);
  }
  
}


