
float refractiveIndex = 1.45;
float brightness = 25.0;
float projectionDistance = 1.0;

PImage rawNormalMap;
PGraphics normalMap;
PVector[] normals;

float pitch = 0.0;
float yaw = 0.0;

PMatrix rotation;

void settings() {
  rawNormalMap = loadImage("resources/normals_lion.png");
  size(rawNormalMap.width + rawNormalMap.width % 2, rawNormalMap.height + rawNormalMap.height % 2); // Just making sure the size is even
}

void setup() {
  normalMap = createGraphics(rawNormalMap.width, rawNormalMap.height);
  // Smooth normal map
  normalMap.beginDraw();
  normalMap.image(rawNormalMap, 0, 0);
  normalMap.filter(BLUR, 0); // It's very sensitive to blurring
  
  // Calculate normals from normal map
  normalMap.loadPixels();
  normals = new PVector[normalMap.pixels.length];
  for (int i = 0; i < normals.length; i ++) {
    normals[i] = new PVector(
      map(red(normalMap.pixels[i]), 0, 255, -1, 1),
      map(green(normalMap.pixels[i]), 0, 255, -1, 1),
      map(blue(normalMap.pixels[i]), 0, 255, -1, 1)
    );
  }
  normalMap.endDraw();
}

void draw() {
  
  if (keyPressed && key == CODED) {
    if (keyCode == UP) {
      projectionDistance = max(projectionDistance - 0.05, 0);
      println(projectionDistance);
    } else if (keyCode == DOWN) {
      projectionDistance = max(projectionDistance + 0.05, 0);
      println(projectionDistance);
    }
  }
  
  
  pitch = map(mouseY, 0, height, PI/4, -PI/4);
  yaw = map(mouseX, 0, width, -PI/4, PI/4);
  
  PMatrix3D rotation = new PMatrix3D();
  
  rotation.rotateX(pitch);
  rotation.rotateY(yaw);
  
  background(0);
  loadPixels();
  
  PVector imageBasisX = mult(rotation, new PVector(1, 0));
  PVector imageBasisY = mult(rotation, new PVector(0, 1));
  PVector mapOffset = new PVector(normalMap.width/2, normalMap.height/2);
  
  PVector l = refract(new PVector(0, 0, 1), mult(rotation, new PVector(0, 0, 1)), 1/refractiveIndex);
  
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      PVector coords = new PVector(x - width/2, y - height/2);
      float transformedY = (coords.y - coords.x * imageBasisX.y / imageBasisX.x) / (imageBasisY.y - imageBasisY.x * imageBasisX.y / imageBasisX.x);
      float transformedX = (coords.x - transformedY * imageBasisY.x) / imageBasisX.x;
      PVector transformed = new PVector(transformedX, transformedY);
      transformed.z = transformed.x * imageBasisX.z + transformed.y * imageBasisY.z;
      transformed.add(mapOffset);
      
      if (transformed.x >= 0 && transformed.x < normalMap.width && transformed.y >= 0 && transformed.y < normalMap.height) {
        PVector normal = mult(rotation, normals[floor(transformed.x) + floor(transformed.y) * normalMap.width]);
        
        PVector v = refract(l, normal, refractiveIndex);
        PVector projected = new PVector(x, y).add(v.mult(max(normalMap.width, normalMap.height) * projectionDistance + transformed.z));

        int px = floor(projected.x);
        int py = floor(projected.y);
        if (px >= 0 && px < width && py >= 0 && py < height) {
          pixels[px + py * width] = color(red(pixels[px + py * width]) + brightness);
        }
        
        //pixels[x + y * width] = color(map(transformed.x, 0, normalMap.width, 0, 255), map(transformed.y, 0, normalMap.height, 0, 255), transformed.z);
      } else {
        pixels[x + y * width] = color(red(pixels[x + y * width]) + brightness);
      }
    }
  }
  updatePixels();
}

PVector refract(PVector l, PVector n, float r) {
  return PVector.mult(l, r).sub(PVector.mult(n, r * n.dot(l) - sqrt(1 - r * r * (1 - pow(n.dot(l), 2)))));
}

PVector mult(PMatrix3D mat, PVector vec) {
  return new PVector(
    mat.m00 * vec.x + mat.m01 * vec.y + mat.m02 * vec.z,
    mat.m10 * vec.x + mat.m11 * vec.y + mat.m12 * vec.z,
    mat.m20 * vec.x + mat.m21 * vec.y + mat.m22 * vec.z
  );
}
