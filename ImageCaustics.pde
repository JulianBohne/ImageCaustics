
class MovedPixel {
  int ogX, ogY;
  
  MovedPixel(int ogX, int ogY) {
    this.ogX = ogX;
    this.ogY = ogY;
  }
  
}

PImage image;
float[] horizontalTargetSum;
float[] verticalTargetSum;

ArrayList<ArrayList<MovedPixel>> currentImage;
ArrayList<ArrayList<MovedPixel>> horizontalCurrent;
ArrayList<ArrayList<MovedPixel>> verticalCurrent;

float noiseOffset = 0.1;

boolean updateImage = true;

int frameOffset;

void setup() {
  size(612, 408); // 408 ist just so the image to mp4 works
  
  image = loadImage("resources/lion-612x407.jpg");
  
  image.loadPixels();
  
  horizontalCurrent = new ArrayList<ArrayList<MovedPixel>>(image.height);
  for (int y = 0; y < image.height; y++) {
    horizontalCurrent.add(new ArrayList<MovedPixel>());
  }
  
  horizontalTargetSum = new float[image.height];
  for (int y = 0; y < image.height; y++) {
    float sum = 0;
    for (int x = 0; x < image.width; x++) {
      sum += gray(image.pixels[x + y*image.width]);
    }
    horizontalTargetSum[y] = sum;
  }
  
  verticalCurrent = new ArrayList<ArrayList<MovedPixel>>(image.width);
  for (int x = 0; x < image.width; x++) {
    verticalCurrent.add(new ArrayList<MovedPixel>());
  }
  
  verticalTargetSum = new float[image.width];
  for (int x = 0; x < image.width; x++) {
    float sum = 0;
    for (int y = 0; y < image.height; y++) {
      sum += gray(image.pixels[x + y*image.width]);
    }
    verticalTargetSum[x] = sum;
  }
  
  // Setup uniform image
  currentImage = new ArrayList<ArrayList<MovedPixel>>(image.pixels.length);
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      currentImage.add(new ArrayList<MovedPixel>());
      currentImage.get(x + y*image.width).add(new MovedPixel(x, y));
    }
  }
}

float gray(color pixelColor) {
  return red(pixelColor)/255.0;
}

void draw() {
  
  background(0);
  
  if (updateImage) {
    updateCurrentImage();
    frameOffset = frameCount;
  }
  
  drawCurrentImage();
  
  // Some hard coded thing
  noiseOffset = max(0.05, noiseOffset - 0.005);
  
  //saveFrame("frames/frame####.png");
  
}

void mousePressed() {
  updateImage = false;
}

void updateCurrentImage() {
  // Horizontal
  for (int y = 0; y < image.height; y++) {
    horizontalCurrent.get(y).clear();
    for (int x = 0; x < image.width; x++) {
      horizontalCurrent.get(y).addAll(currentImage.get(x + y*image.width));
      currentImage.get(x + y*image.width).clear();
    }
  }
  for (ArrayList<MovedPixel> pixel : horizontalCurrent) {
    pixel.sort((a, b) -> Integer.compare(a.ogX, b.ogX));
  }
  
  for (int y = 0; y < image.height; y++) {
    double factor = horizontalTargetSum[y] / float(horizontalCurrent.get(y).size());
    int index = 0;
    for (int x = 0; x < image.width && index < horizontalCurrent.get(y).size() && horizontalTargetSum[y] != 0; x++) {
      ArrayList<MovedPixel> current = currentImage.get(x + y * image.width);
      while (current.size()*factor < gray(image.pixels[x + y * image.width])-noiseOffset && index < horizontalCurrent.get(y).size()) {
        current.add(horizontalCurrent.get(y).get(index));
        index++;
      }
    }
    while (index < horizontalCurrent.get(y).size()) {
      currentImage.get(floor(random(image.width)) + y * image.width).add(horizontalCurrent.get(y).get(index));
      index++;
    }
  }
  
  
  // Vertical
  for (int x = 0; x < image.width; x++) {
    verticalCurrent.get(x).clear();
    for (int y = 0; y < image.height; y++) {
      verticalCurrent.get(x).addAll(currentImage.get(x + y*image.width));
      currentImage.get(x + y*image.width).clear();
    }
  }
  for (ArrayList<MovedPixel> pixel : verticalCurrent) {
    pixel.sort((a, b) -> Integer.compare(a.ogY, b.ogY));
  }
  
  for (int x = 0; x < image.width; x++) {
    double factor = verticalTargetSum[x] / float(verticalCurrent.get(x).size());
    int index = 0;
    for (int y = 0; y < image.height && index < verticalCurrent.get(x).size() && verticalTargetSum[x] != 0; y++) {
      ArrayList<MovedPixel> current = currentImage.get(x + y * image.width);
      while (current.size()*factor < gray(image.pixels[x + y * image.width])-noiseOffset && index < verticalCurrent.get(x).size()) {
        current.add(verticalCurrent.get(x).get(index));
        index++;
      }
    }
    while (index < verticalCurrent.get(x).size()) {
      currentImage.get(x + floor(random(image.height)) * image.width).add(verticalCurrent.get(x).get(index));
      index++;
    }
  }
}

void drawCurrentImage() {
  if (updateImage) {
    float maxLight = 0;
    for (ArrayList<MovedPixel> pixel : currentImage) {
      maxLight = max(maxLight, pixel.size());
    }
    loadPixels();
    for (int i = 0; i < currentImage.size(); i++) {
      pixels[i] = color(map(currentImage.get(i).size(), 0, maxLight, 0, 255));
    }
    updatePixels();
  } else {
    stroke(255, 64);
    strokeWeight(1);
    
    float t = cos((frameCount - frameOffset) * 0.01)*0.5 + 0.5;
    
    for (int i = 0; i < currentImage.size(); i ++) {
      int x = i % image.width;
      int y = i / image.width;
      
      for (MovedPixel pixel : currentImage.get(i)) {
        float px = lerp(pixel.ogX, x, t);
        float py = lerp(pixel.ogY, y, t);
        point(px, py);
      }
    }
  }
}
