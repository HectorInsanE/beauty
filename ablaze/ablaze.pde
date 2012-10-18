// This is a naive implement of ablaze.js in processing
// currently no colormap function
// 

// build config
int PARTICLE_NUM = 40;
int MIN_DIST = 80;
float MIN_SPEED = 0.1;
float MAX_SPEED = 0.5;
float RING_SIZE = 150;
boolean line_connect = true;

// show config
boolean show_vertex = false;
boolean use_color_map = true;
float color_r = 255, color_g = 255, color_b = 255;
float clr;
float NOISE_SCALE = 0.02;
float FRAME_TO_DARKEN = 100;
float frame_cnt = 0;
PImage clrmap;

Particle [] ps;

class Particle {
  public float pre_x, pre_y, x, y, rot_angle;
  private float vx, vy;
  private int step;

  Particle(float x, float y, float v, float v_angle) {
    this.pre_x = x;
    this.pre_y = y;
    this.x = x;
    this.y = y;
    this.vx = v*cos(v_angle);
    this.vy = v*sin(v_angle);
    generate_new_curve();
  }

  public void next() {
    turn(rot_angle);
    pre_x = x;
    pre_y = y;
    x += vx;
    y += vy;
    step--;
    if (step <= 0) {
      generate_new_curve();
    }
  }

  public void turn(float rot) {
    float pvx = vx;
    float pvy = vy;
    vx = pvx * cos(rot) - pvy * sin(rot);
    vy = pvx * sin(rot) + pvy * cos(rot);
  }

  private void generate_new_curve() {
    step = (int)random(80, 300);
    rot_angle = random(-0.01, 0.01);
  }
}

void setup() {
  reset();
}

void reset() {
  size( 900, 600, P2D);
  background(0);
  smooth();

  ps = new Particle[PARTICLE_NUM];

  // init particles
  for (int i = 0; i < PARTICLE_NUM; i++) {
    float v = random(MIN_SPEED, MAX_SPEED);
    float angle = random(0, 2*PI);
    float v_angle = random(0, 2*PI);

    ps[i] = new Particle(RING_SIZE * cos(angle), 
    RING_SIZE * sin(angle), 
    v, 
    v_angle);
  }
  clr = random(1.0);

  // load color map
  load_color_map();
}

void draw() {
  if (use_color_map) {
    colorMode(RGB,255);
    generateGraph( "colormap");
  }
  else {
    filter(INVERT);
    colorMode(HSB,1);
    clr += random(0.0001);
    clr = clr % 1;
    generateGraph("rand");
    filter(INVERT);
  }
}

void generateGraph( String coloring_type) {

  translate(width/2, height/2);
  for (int i = 0; i < PARTICLE_NUM; i++) {
    for (int j = i+1; j < PARTICLE_NUM; j++) {
      float dis = dist(ps[i].x, ps[i].y, ps[j].x, ps[j].y);
      if ( dis < MIN_DIST ) {
        if (coloring_type == "rand") {
          float k = (0.5 + float(i)/2.0) / PARTICLE_NUM;
          fill(clr, pow(k, 0.1), 0.9 * sqrt(1-k), 0.1 * (1  - dis / MIN_DIST));
          stroke(clr, pow(k, 0.1), 0.9 * sqrt(1-k), 0.1 * (1  - dis / MIN_DIST));
        } 
        else if (coloring_type == "colormap") {
          color c = set_color_by_map(ps[i]);
          fill((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF, 32 * (1 - dis / MIN_DIST));
          stroke((c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF, 32 * (1 - dis / MIN_DIST));
        }
        buildConnect(ps[i], ps[j], dis);
      }
    }
    ps[i].next();
  }
}

void keyPressed() {
  switch(key) {
  case 't': 
    changeConnectionBuild(); 
    break;
  case 'r': 
    reset(); 
    break;
  case 'v': 
    changeVertexShow(); 
    break;
  case 's': 
    saveFrame(); 
    break;
  case 'c': 
    changeColor(); 
    break;
  }
}

void buildConnect(Particle p1, Particle p2, float dis) {

  if (line_connect) {
    line(p1.x, p1.y, p2.x, p2.y);
  }
  else {
    float cx = (p1.x + p2.x)/2;
    float cy = (p1.y + p2.y)/2;
    noFill();
    ellipse(cx, cy, dis/2, dis/2);
  }
}

void changeVertexShow() {
  show_vertex = ! show_vertex;
}

void changeConnectionBuild() {
  line_connect = ! line_connect;
}

void changeColor() {
  use_color_map = ! use_color_map;
}

void load_color_map() {
  clrmap = loadImage("data.png");
  blurImage(clrmap);
}

color set_color_by_map(Particle p) {
  if (clrmap.width > 0) {
    if (abs(p.x) >= width/2 - 1 || abs(p.y) >= height/2 - 1) return 0;
    float x = map(p.x, -width/2, width/2, 0, clrmap.width);
    float y = map(p.y, -height/2, height/2, 0, clrmap.height);
    if ((int)((y) * clrmap.width) + (int) (x-1) >= clrmap.width * clrmap.height)
      return 0;
    color c = clrmap.pixels[(int)((y) * clrmap.width) + (int) (x-1)];
    return c;
  }
  return 0;
}

void blurImage(PImage img) {
  float v = 1.0 / 25.0;
  float[][] kernel = {{ v, v, v, v, v }, 
                    { v, v, v, v, v }, 
                    { v, v, v, v, v },
                    { v, v, v, v, v }, 
                    { v, v, v, v, v }};
                    
    // Loop through every pixel in the image
  for (int y = 2; y < img.height-2; y++) {   // Skip top and bottom edges
    for (int x = 2; x < img.width-2; x++) {  // Skip left and right edges
      float sum_r = 0, sum_g = 0, sum_b = 0; // Kernel sum for this pixel
      for (int ky = -2; ky <= 2; ky++) {
        for (int kx = -2; kx <= 2; kx++) {
          // Calculate the adjacent pixel for this kernel point
          int pos = (y + ky)*img.width + (x + kx);
          // Image is grayscale, red/green/blue are identical
          float val_r = red(img.pixels[pos]);
          float val_g = green(img.pixels[pos]);
          float val_b = blue(img.pixels[pos]);
          
          // Multiply adjacent pixels based on the kernel values
          sum_r += kernel[ky+2][kx+2] * val_r;
          sum_g += kernel[ky+2][kx+2] * val_g;
          sum_b += kernel[ky+2][kx+2] * val_b;
        }
      }
      // For this pixel in the new image, set the gray value
      // based on the sum from the kernel
      img.pixels[y*img.width + x] = color(sum_r, sum_g, sum_b);
    }
  }
}

