/*
 * Car Physics Demo
 * version 0.8 3-06-2001
 *
 * Copyright (c) 2001 Monstrous Software
 *
 * Platforms: Allegro/DJGPP, Allegro/Linux, Allegro/MSVC
 *
 * Demonstrates rough approximation of car physics.
 *
 * origin C-code - translated by bloemschneif
 */

import java.awt.*;
import java.awt.event.*;

public class CarPhysics extends java.applet.Applet
{
 PhysicsModule panel;
 public void init()
 {
  setLayout(new BorderLayout());
  panel = new PhysicsModule(true);
  add("Center", panel);
 }

 public void start()
 {
  panel.start();
 }

 public static void main(String a[])
 {
  Frame f = new Frame("Simulating car physics");
  PhysicsModule _panel = new PhysicsModule(false);
  f.add(_panel);
  f.addWindowListener(new WindowClosingAdapter(true));
  _panel.start();
  f.pack();
  f.setVisible(true);
 }
}

class PhysicsModule extends Panel
 implements KeyListener, Runnable
{
  static final int TRAIL_SIZE = 200;     /* number of dots in car trail */
  static final double DELTA_T = 0.01;    /* time between integration steps in physics modelling */
  static final double INPUT_DELTA_T = 0.1;   /* delay between keyboard polls */

  static final double M_PI = 3.1415926;

  class VEC2
  { double x,y; }

  class CARTYPE
  {
    double wheelbase;      // wheelbase in m
    double b;              // in m, distance from CG to front axle
    double c;              // in m, idem to rear axle
    double h;              // in m, height of CM from ground
    double mass;           // in kg
    double inertia;        // in kg.m
    double length,width;
    double wheellength,wheelwidth;
  }

  class CAR
  {
   public CAR ()
   {
    cartype = new CARTYPE();
    position_wc = new VEC2();
    velocity_wc = new VEC2();
   }
    CARTYPE cartype;        // pointer to static car data

    VEC2 position_wc;       // position of car centre in world coordinates
    VEC2 velocity_wc;       // velocity vector of car in world coordinates

    double angle;           // angle of car body orientation (in rads)
    double angularvelocity;

    double steerangle;      // angle of steering (input)
    double throttle;        // amount of throttle (input)
    double brake;           // amount of braking (input)
  }

  class TRAILPOINT
  {
    double x,y;
    double angle;
  }

  CARTYPE []cartypes = new CARTYPE[1];
  VEC2    screen_pos;
  double  scale;
  String  str;
  int     ticks = 1;        // ticks of DELTA_T second
  int     iticks = 1;       // ticks of INPUT_DELTA_T second
  TRAILPOINT [] trail = new TRAILPOINT [ TRAIL_SIZE ];
  int     num_trail = 0;


  VEC2       velocity;
  VEC2       acceleration_wc;
  double     rot_angle;
  double     sideslip;
  double     slipanglefront;
  double     slipanglerear;
  VEC2       force;
  int        rear_slip;
  int        front_slip;
  VEC2       resistance;
  VEC2       acceleration;
  double     torque;
  double     angular_acceleration;
  double     sn, cs;
  double     yawspeed;
  double     weight;
  VEC2       ftraction;
  VEC2       flatf, flatr;

  void ticks_timer(  )
  { ticks++; }

  void iticks_timer(  )
  { iticks++; }

  void init_trail(  )
  {
   num_trail = 0;
   for (int i=0; i<TRAIL_SIZE; i++)
     trail[i] = new TRAILPOINT ();
  }

  void draw_trail( Graphics g, CAR car )
  {
   int i;
   int x,y;

   g.setColor(Color.gray);

   for(i = 0; i < num_trail; i++)
   {
     x = (int)( (trail[i].x-car.position_wc.x)*scale+screen_pos.x);
     y = (int)(-(trail[i].y-car.position_wc.y)*scale+screen_pos.y);
     g.drawOval(x, y, 2, 2);
   }
  }

  void add_to_trail( double x, double y, double angle )
  {
   if( num_trail < TRAIL_SIZE-1 )
   {
     trail[num_trail].x = x;
     trail[num_trail].y = y;
     trail[num_trail].angle = angle;
     num_trail++;
    }
     else
     {
     //  System.arraycopy(trail, 1, trail, 0, TRAIL_SIZE-1);
      for (int i=0; i< TRAIL_SIZE-1; i++)
      {
       trail[i].x = trail[i+1].x;
       trail[i].y = trail[i+1].y;
       trail[i].angle = trail[i+1].angle;
      }
       trail[num_trail].x = x;
       trail[num_trail].y = y;
       trail[num_trail].angle = angle;
     }
  }

  void draw_rect( Graphics g, double angle, int w, int l, int x, int y, int crossed)
  {
    VEC2 []c  = new VEC2[4];
    VEC2 []c2 = new VEC2[4];
    for (int i=0; i<4; i++)
    {
     c[i]  = new VEC2();
     c2[i] = new VEC2();
    }
    double sn, cs;
    int i;

    sn = Math.sin(angle);
    cs = Math.cos(angle);

    c[0].x = -w/2;
    c[0].y = l/2;

    c[1].x = w/2;
    c[1].y = l/2;

    c[2].x = w/2;
    c[2].y = -l/2;

    c[3].x = -w/2;
    c[3].y = -l/2;

    for(i = 0; i <= 3; i++)
    {
     c2[i].x = cs*c[i].x - sn*c[i].y;
     c2[i].y = sn*c[i].x + cs*c[i].y;
     c[i].x = c2[i].x;
     c[i].y = c2[i].y;
    }

    for(i = 0; i <= 3; i++)
    {
     c[i].x += x;
     c[i].y += y;
    }
     g.setColor(Color.black);
     g.drawLine((int)c[0].x, (int)c[0].y, (int)c[1].x, (int)c[1].y);
     g.drawLine((int)c[1].x, (int)c[1].y, (int)c[2].x, (int)c[2].y);
     g.drawLine((int)c[2].x, (int)c[2].y, (int)c[3].x, (int)c[3].y);
     g.drawLine((int)c[3].x, (int)c[3].y, (int)c[0].x, (int)c[0].y);

    if(crossed==1)
    {
     g.drawLine( (int)c[0].x, (int)c[0].y, (int)c[2].x, (int)c[2].y);
     g.drawLine( (int)c[1].x, (int)c[1].y, (int)c[3].x, (int)c[3].y);
    }
  }

  void draw_wheel( int nr, Graphics g, CAR car, int x, int y, int crossed)
  {
    draw_rect(g, car.angle+(nr<2 ? car.steerangle : 0),
                (int)(car.cartype.wheelwidth*scale),
                (int)(car.cartype.wheellength*scale), x, y, crossed );
  }

  void render(Graphics g, CAR car)
  {
   VEC2 []corners = new VEC2[4];
   VEC2 []wheels  = new VEC2[4];
   VEC2 []w       = new VEC2[4];
   VEC2 scrpos;
   for (int i=0; i<4; i++)
   {
    corners[i] = new VEC2();
    wheels[i]  = new VEC2();
    w[i]       = new VEC2();
   }
   scrpos = new VEC2();

   double sn, cs;
   int i;
   int y;

   Rectangle r = getBounds();
   g.setColor(new Color(0x31E67D));
   g.fillRect(0,0, r.width-1, r.height-1);

   sn = Math.sin(car.angle);
   cs = Math.cos(car.angle);

   screen_pos.x =  car.position_wc.x * scale + r.width/2;
   screen_pos.y = -car.position_wc.y * scale + r.height/2;

   while(screen_pos.y < 0)
        screen_pos.y += r.height;
   while(screen_pos.y > r.height)
        screen_pos.y -= r.height;
   while(screen_pos.x < 0)
        screen_pos.x += r.width;
   while(screen_pos.x > r.width)
        screen_pos.x -= r.width;

   draw_trail( g, car );

   g.setColor(Color.black);

   corners[0].x = -car.cartype.width/2;
   corners[0].y = -car.cartype.length/2;

   corners[1].x = car.cartype.width/2;
   corners[1].y = -car.cartype.length/2;

   corners[2].x = car.cartype.width/2;
   corners[2].y = car.cartype.length/2;

   corners[3].x = -car.cartype.width/2;
   corners[3].y = car.cartype.length/2;

   for(i = 0; i <= 3; i++)
   {
    w[i].x = cs*corners[i].x - sn*corners[i].y;
    w[i].y = sn*corners[i].x + cs*corners[i].y;
    corners[i].x = w[i].x;
    corners[i].y = w[i].y;
   }

   for(i = 0; i <= 3; i++)
   {
    corners[i].x *= scale;
    corners[i].y *= scale;
    corners[i].x += screen_pos.x;
    corners[i].y += screen_pos.y;
   }

   g.drawLine( (int)corners[0].x, (int)corners[0].y, (int)corners[1].x, (int)corners[1].y);
   g.drawLine( (int)corners[1].x, (int)corners[1].y, (int)corners[2].x, (int)corners[2].y);
   g.drawLine( (int)corners[2].x, (int)corners[2].y, (int)corners[3].x, (int)corners[3].y);
   g.drawLine( (int)corners[3].x, (int)corners[3].y, (int)corners[0].x, (int)corners[0].y);

   wheels[0].x = -car.cartype.width/2;
   wheels[0].y = -car.cartype.b;

   wheels[1].x = car.cartype.width/2;
   wheels[1].y = -car.cartype.b;

   wheels[2].x = car.cartype.width/2;
   wheels[2].y = car.cartype.c;

   wheels[3].x = -car.cartype.width/2;
   wheels[3].y = car.cartype.c;

   for(i = 0; i <= 3; i++)
   {
    w[i].x = cs*wheels[i].x - sn*wheels[i].y;
    w[i].y = sn*wheels[i].x + cs*wheels[i].y;
    wheels[i].x = w[i].x;
    wheels[i].y = w[i].y;
   }

   for(i = 0; i <= 3; i++)
   {
    wheels[i].x *= scale;
    wheels[i].y *= scale;
    wheels[i].x += screen_pos.x;
    wheels[i].y += screen_pos.y;
   }

   draw_wheel( 0, g, car, (int)wheels[0].x, (int)wheels[0].y, front_slip);
   draw_wheel( 1, g, car, (int)wheels[1].x, (int)wheels[1].y, front_slip);
   draw_wheel( 2, g, car, (int)wheels[2].x, (int)wheels[2].y, rear_slip);
   draw_wheel( 3, g, car, (int)wheels[3].x, (int)wheels[3].y, rear_slip);

        // Velocity vector dial
        //
   int VDIAL_X = 550;
   int VDIAL_Y = 120;
   g.drawOval( VDIAL_X-50, VDIAL_Y-50, 100, 100);
   g.drawLine( VDIAL_X, VDIAL_Y, (int)(VDIAL_X+velocity.x), (int)(VDIAL_Y-velocity.y));

   int VWDIAL_X = 550;
   int VWDIAL_Y = 260;
   g.drawOval( VWDIAL_X-50, VWDIAL_Y-50, 100, 100);
   g.drawLine( VWDIAL_X, VWDIAL_Y, (int)(VWDIAL_X+car.velocity_wc.x), (int)(VWDIAL_Y-car.velocity_wc.y));

   int THROTTLE_X = 400;
   int THROTTLE_Y = 120;
   g.drawLine( THROTTLE_X, THROTTLE_Y, THROTTLE_X, THROTTLE_Y-100);
   g.drawLine( THROTTLE_X+1, THROTTLE_Y, THROTTLE_X+1, (int)(THROTTLE_Y-car.throttle));

   int BRAKE_X = 440;
   int BRAKE_Y = 120;
   g.drawLine( BRAKE_X, BRAKE_Y, BRAKE_X, BRAKE_Y-100);
   g.drawLine( BRAKE_X+1, BRAKE_Y, BRAKE_X+1, (int)(BRAKE_Y-car.brake));

   int STEER_X = 420;
   int STEER_Y = 160;
   g.drawArc( STEER_X-25,STEER_Y-30,(50),(50), 30, 120);
   g.drawLine( STEER_X,STEER_Y, STEER_X+(int)(Math.sin(car.steerangle)*30.0), STEER_Y-(int)(Math.cos(car.steerangle)*30.0));

   int SLIP_X = 420;
   int SLIP_Y = 200;
   g.drawArc( SLIP_X-25,SLIP_Y-30,(50),(50), 30, 120);
   g.drawLine( SLIP_X,SLIP_Y, SLIP_X+(int)(Math.sin(sideslip)*30.0), SLIP_Y-(int)(Math.cos(sideslip)*30.0));

   int ROT_X = 420;
   int ROT_Y = 240;
   g.drawArc( ROT_X-25,ROT_Y-30,(50),(50), 30, 120);
   g.drawLine( ROT_X,ROT_Y, ROT_X+(int)(Math.sin(rot_angle)*30.0), ROT_Y-(int)(Math.cos(rot_angle)*30.0));

   int AF_X = 450;
   int AF_Y = 280;
   g.drawArc( AF_X-25,AF_Y-30,(50),(50), 30, 120);
   g.drawLine( AF_X,AF_Y, AF_X+(int)(Math.sin(slipanglefront)*30.0), AF_Y-(int)(Math.cos(slipanglefront)*30.0));

   int AR_X = 450;
   int AR_Y = 320;
   g.drawArc( AR_X-25,AR_Y-30,(50),(50), 30, 120);
   g.drawLine( AR_X,AR_Y, AR_X+(int)(Math.sin(slipanglerear)*30.0), AR_Y-(int)(Math.cos(slipanglerear)*30.0));

   int TEXT_X = 10;
   y = 0;
   g.drawString ("scale        "+scale+" pixels/m <Q,W>", TEXT_X, y+=16);
   g.drawString ("alpha front  "+(slipanglefront *180.0/M_PI)+" deg", TEXT_X, y+=16);
   g.drawString ("alpha rear   "+ (slipanglerear * 180.0/M_PI) +" deg", TEXT_X, y+=16);
   g.drawString ("f.lat front  "+flatf.y+" N", TEXT_X, y+=16 );
   g.drawString ("f.lat rear   "+flatr.y+" N",TEXT_X, y+=16 );
   g.drawString ("force.x      "+ force.x +" N",TEXT_X, y+=16 );
   g.drawString ("force.y      "+ force.y +" N", TEXT_X, y+=16 );
   g.drawString ("torque       " + torque + " Nm", TEXT_X, y+=16 );
   g.drawString ("ang.vel.     "+ car.angularvelocity +" rad/s", TEXT_X, y+=16);
   g.drawString ("Esc=quit Q/W=zoom RCtrl=brake Up/Down=accelerator Space=4wheel slip", 0, r.height-16 );
 }

/*
 * Physics module
 */
 void init_cartypes(  )
 {
  CARTYPE cartype;

  cartype = cartypes[0];
  cartype.b = 1.0;                               // m
  cartype.c = 1.0;                               // m
  cartype.wheelbase = cartype.b + cartype.c;
  cartype.h = 1.0;                               // m
  cartype.mass = 1500;                           // kg
  cartype.inertia = 1500;                        // kg.m
  cartype.width = 1.5;                           // m
  cartype.length = 3.0;                           // m, must be > wheelbase
  cartype.wheellength = 0.7;
  cartype.wheelwidth = 0.3;
 }

 void init_car( CAR car, CARTYPE cartype )
 {
  car.cartype = cartype;
  car.position_wc.x = 0;
  car.position_wc.y = 0;
  car.velocity_wc.x = 0;
  car.velocity_wc.y = 0;
  car.angle = 0;
  car.angularvelocity = 0;
  car.steerangle = 0;
  car.throttle = 0;
  car.brake = 0;
 }

 double SGN (double value)
 { if (value < 0.0) return -1.0; else return 1.0; }

 double ABS (double value)
 { if (value < 0.0) return -value; else return value; }

// These constants are arbitrary values, not realistic ones.

 static final double DRAG        = 5.0;     /* factor for air resistance (drag)         */
 static final double RESISTANCE  = 30.0;    /* factor for rolling resistance */
 static final double CA_R        = -5.20;   /* cornering stiffness */
 static final double CA_F        = -5.0;    /* cornering stiffness */
 static final double MAX_GRIP    = 2.0;     /* maximum (normalised) friction force, =diameter of friction circle */

 void do_physics( CAR car, double delta_t )
 {
  sn = Math.sin(car.angle);
  cs = Math.cos(car.angle);
  // SAE convention: x is to the front of the car, y is to the right, z is down
  // transform velocity in world reference frame to velocity in car reference frame
  velocity.x =  cs * car.velocity_wc.y + sn * car.velocity_wc.x;
  velocity.y = -sn * car.velocity_wc.y + cs * car.velocity_wc.x;

 // Lateral force on wheels
 //
   // Resulting velocity of the wheels as result of the yaw rate of the car body
   // v = yawrate * r where r is distance of wheel to CG (approx. half wheel base)
   // yawrate (ang.velocity) must be in rad/s
   //
   yawspeed = car.cartype.wheelbase * 0.5 * car.angularvelocity;

   if( velocity.x == 0 )                // TODO: fix Math.singularity
        rot_angle = 0;
   else
    rot_angle = Math.atan( yawspeed / velocity.x);
   // Calculate the side slip angle of the car (a.k.a. beta)
   if( velocity.x == 0 )                // TODO: fix Math.singularity
        sideslip = 0;
   else
    sideslip = Math.atan( velocity.y / velocity.x);

   // Calculate slip angles for front and rear wheels (a.k.a. alpha)
   slipanglefront = sideslip + rot_angle - car.steerangle;
   slipanglerear  = sideslip - rot_angle;

   // weight per axle = half car mass times 1G (=9.8m/s^2)
   weight = car.cartype.mass * 9.8 * 0.5;

   // lateral force on front wheels = (Ca * slip angle) capped to friction circle * load
   flatf.x = 0;
   flatf.y = CA_F * slipanglefront;
   flatf.y = Math.min(MAX_GRIP, flatf.y);
   flatf.y = Math.max(-MAX_GRIP, flatf.y);
   flatf.y *= weight;
   if(front_slip==1)
       flatf.y *= 0.5;

   // lateral force on rear wheels
   flatr.x = 0;
   flatr.y = CA_R * slipanglerear;
   flatr.y = Math.min(MAX_GRIP, flatr.y);
   flatr.y = Math.max(-MAX_GRIP, flatr.y);
   flatr.y *= weight;
   if(rear_slip==1)
     flatr.y *= 0.5;

   // longtitudinal force on rear wheels - very simple traction model
   ftraction.x = 100*(car.throttle - car.brake*SGN(velocity.x));
   ftraction.y = 0;
   if(rear_slip==1)
     ftraction.x *= 0.5;

// Forces and torque on body

   // drag and rolling resistance
   resistance.x = -( RESISTANCE*velocity.x + DRAG*velocity.x*ABS(velocity.x) );
   resistance.y = -( RESISTANCE*velocity.y + DRAG*velocity.y*ABS(velocity.y) );

   // sum forces
   force.x = ftraction.x + Math.sin(car.steerangle) * flatf.x + flatr.x + resistance.x;
   force.y = ftraction.y + Math.cos(car.steerangle) * flatf.y + flatr.y + resistance.y;

   // torque on body from lateral forces
   torque = car.cartype.b * flatf.y - car.cartype.c * flatr.y;

// Acceleration

   // Newton F = m.a, therefore a = F/m
   acceleration.x = force.x/car.cartype.mass;
   acceleration.y = force.y/car.cartype.mass;
   angular_acceleration = torque / car.cartype.inertia;

// Velocity and position

   // transform acceleration from car reference frame to world reference frame
   acceleration_wc.x =  cs * acceleration.y + sn * acceleration.x;
   acceleration_wc.y = -sn * acceleration.y + cs * acceleration.x;

   // velocity is integrated acceleration
   //
   car.velocity_wc.x += delta_t * acceleration_wc.x;
   car.velocity_wc.y += delta_t * acceleration_wc.y;

   // position is integrated velocity
   //
   car.position_wc.x += delta_t * car.velocity_wc.x;
   car.position_wc.y += delta_t * car.velocity_wc.y;


// Angular velocity and heading

   // integrate angular acceleration to get angular velocity
   //
   car.angularvelocity += delta_t * angular_acceleration;

   // integrate angular velocity to get angular orientation
   //
   car.angle += delta_t * car.angularvelocity ;
 }

/*
 * End of Physics module
 */


/*
 * Input module
 */

 boolean kUp, kDown, kLeft, kRight, kQ, kW, kSpace, kCtrl, kESC;
 void initKeys()
 {
  kUp = false;
  kDown = false;
  kLeft = false;
  kRight = false;
  kQ = false; kW = false;
  kSpace = false; kCtrl = false; kESC = false;
 }

 public void keyPressed (KeyEvent e)
 {
  switch (e.getKeyCode())
  {
   case 38 : kUp = true; break;
   case 40 : kDown = true; break;
   case 37 : kLeft = true; break;
   case 39 : kRight = true; break;
   case 17 : kCtrl = true; break;
   case 32 : kSpace = true; break;
   case 81 : kQ = true; break;
   case 87 : kW = true; break;
   case 27 : kESC = true; break;
  }
 }

 public void keyReleased (KeyEvent e)
 {
  switch (e.getKeyCode())
  {
   case 38 : kUp = false; break;
   case 40 : kDown = false; break;
   case 37 : kLeft = false; break;
   case 39 : kRight = false; break;
   case 17 : kCtrl = false; break;
   case 32 : kSpace = false; break;
   case 81 : kQ = false; break;
   case 87 : kW = false; break;
   case 27 : kESC = false; break;
  }
 }

 public void handleKeyEvent()
 {
   if (kESC) {if (applet==false) {quit=1; System.exit(0);} }
   if( kUp ) if( car.throttle < 100) car.throttle += 10;
   if( kDown ) if( car.throttle >= 10) car.throttle -= 10;
   if( kCtrl )
   {
     car.brake = 100;
     car.throttle = 0;
   } else car.brake = 0;
   if( kLeft )
   {
     if( car.steerangle > - M_PI/4.0 ) car.steerangle -= M_PI/32.0;
   } else if( kRight )
     {
       if( car.steerangle <  M_PI/4.0 ) car.steerangle += M_PI/32.0;
     }
   if( kQ ) scale+=1.0;
   if( kW ) scale-=1.0;
    // Let front, rear or both axles slip
       rear_slip = 0;
       front_slip = 0;
    if( kSpace )
    {
     front_slip = 1;
     rear_slip = 1;
    }
 }

 public void keyTyped (KeyEvent e)
 {}

/*
 * End of Input module
 */

 //doppelpuffer zeug
    Image offscreen;
    Dimension offscreensize;
    Graphics offgraphics;

    public void update(Graphics g) {
    Dimension d = new Dimension(640, 480);
        if ((offscreen == null) || (d.width != offscreensize.width) || (d.height != offscreensize.height)) {
            offscreen = createImage(d.width, d.height);
            offscreensize = d;
            if (offgraphics != null) {
                offgraphics.dispose();
            }
            offgraphics = offscreen.getGraphics();
            offgraphics.setFont(getFont());
        }

        offgraphics.setColor(new Color(0x31E67D));
        offgraphics.fillRect(0, 0, d.width, d.height);
        //draw here
        paint(offgraphics);
        //bis hier
        g.drawImage(offscreen, 0, 0, null);
    }

    public void paint(Graphics g)
    {
     render (g, car);
    }

 Thread runner;
 public void start()
 {
  if (runner == null)
  {
   runner = new Thread(this);
   runner.start();
  }
 }

 public void run()
 {
  while(runner != null)
  {
   handleKeyEvent();
   // Call movement functions once per tick
   do_physics(car, DELTA_T);
   add_to_trail( car.position_wc.x, car.position_wc.y, car.angle );
   ticks_timer(  );
   iticks_timer(  );
   repaint();
   try {runner.sleep(15);}
    catch(Exception e) {}
  }
 }


 CAR car;
 int quit;
 boolean applet;

 public PhysicsModule ( boolean runAsApplet )
 {
   super();
   applet = runAsApplet;
   addKeyListener(this);
   initKeys();
   car = new CAR();
   cartypes[0] = new CARTYPE();
   screen_pos = new VEC2();
   ftraction = new VEC2();
   flatf = new VEC2();
   flatr = new VEC2();
   resistance = new VEC2();
   acceleration = new VEC2();
   force = new VEC2();
   velocity = new VEC2();
   acceleration_wc = new VEC2();

   int lastticks=0;
   int lastiticks = 0;

   // initial scale of rendering
   scale = 10;     // pixels per m

   init_cartypes();
   init_car( car, cartypes[0] );

   init_trail();

   quit = 0;
 }

 public Dimension getPreferredSize()
 { return new Dimension(640, 480); }

}
