
class MovedPixel {
  int ogX, ogY;
  
  MovedPixel(int ogX, int ogY) {
    this.ogX = ogX;
    this.ogY = ogY;
  }
  
}

PImage image;
double[] horizontalTargetSum;
double[] verticalTargetSum;

ArrayList<ArrayList<MovedPixel>> currentImage;
ArrayList<ArrayList<MovedPixel>> horizontalCurrent;
ArrayList<ArrayList<MovedPixel>> verticalCurrent;

boolean updateImage = true;

int frameOffset;

double refractiveIndex = 1.45;

void setup() {
  // Lion
  size(612, 408); // 408 ist just so the image to mp4 works
  image = loadImage("resources/lion-612x407.jpg");
  
  //// Circle / Torus
  //size(639, 360);
  //image = loadImage("resources/circle-639-360.jpg");
  
  image.loadPixels();
  
  horizontalCurrent = new ArrayList<ArrayList<MovedPixel>>(image.height);
  for (int y = 0; y < image.height; y++) {
    horizontalCurrent.add(new ArrayList<MovedPixel>());
  }
  
  horizontalTargetSum = new double[image.height];
  for (int y = 0; y < image.height; y++) {
    double sum = 0;
    for (int x = 0; x < image.width; x++) {
      sum += gray(image.pixels[x + y*image.width]);
    }
    horizontalTargetSum[y] = sum;
  }
  
  verticalCurrent = new ArrayList<ArrayList<MovedPixel>>(image.width);
  for (int x = 0; x < image.width; x++) {
    verticalCurrent.add(new ArrayList<MovedPixel>());
  }
  
  verticalTargetSum = new double[image.width];
  for (int x = 0; x < image.width; x++) {
    double sum = 0;
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

double gray(color pixelColor) {
  return pow(red(pixelColor)/255.0, 1.0);
}

void draw() {
  
  background(0);
  
  if (updateImage) {
    updateCurrentImage();
    println(getMeanMovement());
    frameOffset = frameCount;
  }
  
  drawCurrentImage();
  //saveFrame("frames/frame####.png");
  
}

void mousePressed() {
  if (updateImage) {
    createNormalMap();
  }
  
  updateImage = false;
}

void createNormalMap() {
  PGraphics normalMap = createGraphics(image.width, image.height);
  
  // TODO: Create the normal map
  
}

float getMeanMovement() {
  
  float totalMovement = 0;
  int count = 0;
  
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      for (MovedPixel px : currentImage.get(x + y * image.width)) {
        totalMovement += dist(x, y, px.ogX, px.ogY);
        count ++;
      }
    }
  }
  
  return totalMovement / count;
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
    double factor = horizontalTargetSum[y] / (double)(horizontalCurrent.get(y).size());
    int index = 0;
    double targetSum = 0.0;
    if (horizontalTargetSum[y] != 0) {
      for (int x = 0; x < image.width && index < horizontalCurrent.get(y).size(); x++) {
        ArrayList<MovedPixel> current = currentImage.get(x + y * image.width);
        targetSum += gray(image.pixels[x + y * image.width]);
        while (index*factor < targetSum && index < horizontalCurrent.get(y).size()) {
          current.add(horizontalCurrent.get(y).get(index));
          index++;
        }
      }
    } else {
      while (index < horizontalCurrent.get(y).size()) {
        currentImage.get(floor(random(image.width)) + y * image.width).add(horizontalCurrent.get(y).get(index));
        index++;
      }
    }
    assert(index == horizontalCurrent.get(y).size());
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
    double factor = verticalTargetSum[x] / (double)(verticalCurrent.get(x).size());
    int index = 0;
    double targetSum = 0;
    if (verticalTargetSum[x] != 0) {
      for (int y = 0; y < image.height && index < verticalCurrent.get(x).size(); y++) {
        ArrayList<MovedPixel> current = currentImage.get(x + y * image.width);
        targetSum += gray(image.pixels[x + y * image.width]);
        while (index*factor < targetSum && index < verticalCurrent.get(x).size()) {
          current.add(verticalCurrent.get(x).get(index));
          index++;
        }
      }
    } else {
      while (index < verticalCurrent.get(x).size()) {
        currentImage.get(x + floor(random(image.height)) * image.width).add(verticalCurrent.get(x).get(index));
        index++;
      }
    }
    assert(index == verticalCurrent.get(x).size());
  }
}

void drawCurrentImage() {
  float maxLight = 0;
  for (ArrayList<MovedPixel> pixel : currentImage) {
    maxLight = max(maxLight, pixel.size());
  }
  loadPixels();
  if (updateImage) {
    for (int i = 0; i < currentImage.size(); i++) {
      pixels[i] = color(map(currentImage.get(i).size(), 0, maxLight, 0, 255));
    }
  } else {
    float t = cos((frameCount - frameOffset) * 0.01)*0.5 + 0.5;
    
    for (int i = 0; i < currentImage.size(); i ++) {
      int x = i % image.width;
      int y = i / image.width;
      
      for (MovedPixel pixel : currentImage.get(i)) {
        float px = lerp(pixel.ogX, x, t);
        float py = lerp(pixel.ogY, y, t);
        pixels[floor(px) + floor(py) * image.width] = color(red(pixels[floor(px) + floor(py) * image.width]) + 255.0/maxLight);
      }
    }
  }
  updatePixels();
}
