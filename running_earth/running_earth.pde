// A processing implementation to generate effects in 
// http://visualize.yahoo.com/core/
// Wenzhong @ Beijing, Jun 2012 

import traer.physics.*;
import geomerative.*;

float t=0;
int n = 200;
float init_angle[] = new float[n];
float init_y[] = new float[n];  // default height of particles
float clr = random(1);
float tail_transparent = 0.3;
float imgscale = 1;
float to = 1;
PFont impact;
String title_core = "C O R E";
float radius_v = 0.02;

ParticleSystem physics;
Particle o;
Particle textcenter[] = new Particle[4];
float nebula_radius = 70;
float nebula_count = 50;
float nebula_x_offset = -120;
float nebula_y_offset = 0;
float nebula_gap = 80;
float nebula_particle_radius = 5;

//switches
boolean core_nebula = true;
boolean item_track = true;
boolean print_title = true;

RFont rfont;

void setup() {
  size(screen.width, screen.height, P2D);
  background(0);
  smooth();

  // init earth
  for (int i = 0; i < n; i++) {
    init_angle[i] = random(TWO_PI);
    init_y[i] = random(height) - height/2;
  }
  frameRate(60);
  impact = loadFont("Impact-96.vlw");
  textFont(impact, 96);

  // init c.o.r.e nebula
  physics = new ParticleSystem(0, 0); // without gravity

  for (int i = 0 ; i < textcenter.length; i++) {
    Particle c = physics.makeParticle(5, nebula_x_offset + i * nebula_gap, 0, 0);
    c.makeFixed();
    for (int j = 0 ; j < nebula_count; j++) {
      float theta = random(0, TWO_PI);
      float sx = c.position().x();
      float sy = c.position().y();
      o = physics.makeParticle(1, sx + nebula_radius * cos(theta), sy + nebula_radius * sin(theta), 0);
      o.velocity().set( random(-5, 5), random(-5, 5), 0);
      physics.makeAttraction(c, o, 1000, 45);
    }
  }
  
  // Geomerative Init
  RG.init(this);
  rfont = new RFont("Impact.ttf",128, RFont.CENTER);
}

void draw() {
  if (pow((mouseX-width/2),2) + pow((mouseY-height/2),2) < pow(height/2,2))
    radius_v = 0.005;
  else
    radius_v = 0.02;
  t += radius_v;
  t = t % TWO_PI;
  clr += random(0.01);
  clr = clr % 1;

  fill(0, tail_transparent);   // set a little tail for meteor
  rect(0, 0, width, height);

  translate(width/2, height/2);
  stroke(0, 0);
  filter(INVERT);
  colorMode(HSB, 1);

  imgscale += ( to - imgscale) / 10; 

  if ( item_track) {
    for (int i = 0; i < n; i++) {
      // drawing balls in a ellipse curves
      // for ellipse: ((x-h)/a)^2 + ((y-k)/b)^2 = 1
      // it can be transformed as: x = h + acos(t),  y = k + bsin(t);
      float angle = t + init_angle[i];
      float x = sqrt(sq(height/2) - sq(init_y[i])) * cos(angle);
      float y = init_y[i] + 50 * (1 - abs(init_y[i] * 2 / height)) * sin(angle);
      float r = nebula_particle_radius - nebula_particle_radius/4 * sin(angle);

      // a color algorithm from Claudio Gonzales
      float k = float(i) / n;
      fill(clr, pow(k, 0.1), 0.9*sqrt(1-k), r/5);

      // draw the particle
      ellipse( imgscale*x, imgscale*y, r, r);
    }
  }

  if ( core_nebula) {
    physics.tick();
    for (int i = 0 ; i < physics.numberOfParticles() ; i++) { 
      o = physics.getParticle(i);
      if (o.isFixed())
        continue;

      float k = float(i) / physics.numberOfParticles();
      fill(1 - clr, pow(k, 0.1), 0.9*sqrt(1-k), 0.4);
      ellipse(o.position().x(), o.position().y(), 4, 4);
    }
  }
  
  if ( print_title) {
    translate(0,48);
    printTitle(title_core);
  }
    
  filter(INVERT);
}

void keyPressed() {
  if (key == 'j' && imgscale < 2) {
    to = imgscale + 0.05;
  }
  else if (key == 'k' && imgscale > 0.3) {
    to = imgscale - 0.05;
  }

  else if (key == 'n') {
    core_nebula = !core_nebula;
  }

  else if (key == 'i') {
    item_track = !item_track;
  }
  
  else if (key == 't') {
    print_title = !print_title;
  }
}

void printTitle(String title) {
//  fill(0.5);
//  textAlign(CENTER, CENTER);
//  text(title, -150, -150, 300, 300);
  RGroup grp = rfont.toGroup(title_core);
  RCommand.setSegmentLength(random(5,10));
  RCommand.setSegmentator(RCommand.UNIFORMLENGTH);
  
  RPoint[] pnts = grp.getPoints();
  for (int i = 0; i < pnts.length; i++) {
    ellipse(pnts[i].x, pnts[i].y, 6,6);
  }
}

