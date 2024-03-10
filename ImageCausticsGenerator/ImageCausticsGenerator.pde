
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

float projectionDistance = 1.0;
float refractiveIndex = 1.45;

PGraphics normalMap;

void settings() {
  
  //// Albert Einstein
  //image = loadImage("resources/albert.jpg");
  
  // Lion
  image = loadImage("resources/lion-612x407.jpg");
  
  //// Circle / Torus
  //image = loadImage("resources/circle-639-360.jpg");
  
  //// Lines
  //image = loadImage("resources/lines-612x321.jpg");
  
  //// Moon
  //image = loadImage("resources/moon-716x693.jpg");
  
  //// Skull xray
  //image = loadImage("resources/skull.jpg");
  
  size(image.width + image.width % 2, image.height + image.height % 2); // Just making sure the size is even
}

void setup() {
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
  return pow(red(pixelColor)/255.0, 2.0);
}

void draw() {
  
  background(0);
  
  if (updateImage) {
    updateCurrentImage();
    println(getMeanMovement());
    frameOffset = frameCount;
  }
  
  drawCurrentImage();
}

void mousePressed() {
  if (updateImage) {
    createNormalMap();
  }
  
  updateImage = false;
}

void createNormalMap() {
  colorMode(RGB);
  
  normalMap = createGraphics(image.width, image.height);
  normalMap.beginDraw();
  normalMap.background(color(
    map(0, -1, 1, 0, 255),
    map(0, -1, 1, 0, 255),
    map(1, -1, 1, 0, 255),
    255
  ));
  
  normalMap.loadPixels();
  
  float scaleFactor = 1.0 / max(image.width, image.height);
  
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      for (MovedPixel px : currentImage.get(x + y * image.width)) {
        PVector refractDir = new PVector(x - px.ogX, y - px.ogY, 0).mult(scaleFactor).div(projectionDistance);
        refractDir.z = 1.0;
        refractDir.normalize();
        
        PVector normal = new PVector(0, 0, refractiveIndex).sub(refractDir).normalize();
        
        PVector sanityCheck = refract(normal).sub(refractDir);
        if (!(sanityCheck.mag() < 0.001))
          println("Found a bad refraction: " + refractDir);
        
        normalMap.pixels[px.ogX + px.ogY * image.width] = color(
          map(normal.x, -1, 1, 0, 255),
          map(normal.y, -1, 1, 0, 255),
          map(normal.z, -1, 1, 0, 255),
          255
        );
      }
    }
  }
  normalMap.updatePixels();
  normalMap.endDraw();
  
  normalMap.save("normals.png");
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
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        pixels[x + y * width] = color(map(currentImage.get(x + y * image.width).size(), 0, maxLight, 0, 255));
      }
    }
  } else {
    float t = cos((frameCount - frameOffset) * 0.01)*0.5 + 0.5;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        for (MovedPixel pixel : currentImage.get(x + y * image.width)) {
          float px = lerp(pixel.ogX, x, t);
          float py = lerp(pixel.ogY, y, t);
          pixels[floor(px) + floor(py) * width] = color(red(pixels[floor(px) + floor(py) * width]) + 255.0/maxLight);
        }
      }
    }
  }
  updatePixels();
}

PVector refract(PVector n) {
  return new PVector(0, 0, refractiveIndex).sub(PVector.mult(n, refractiveIndex * n.z - sqrt(1 - refractiveIndex*refractiveIndex*(1 - n.z*n.z))));
}
