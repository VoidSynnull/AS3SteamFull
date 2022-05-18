package game.scenes.examples.particlesExample
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.creators.entity.EmitterCreator;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.examples.particlesExample.particles.ParticleExample1;
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Pulse;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.displayObjects.Star;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.common.initializers.SharedImage;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AntiGravity;
	import org.flintparticles.twoD.actions.CircularAcceleration;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Rotation;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.renderers.BitmapRenderer;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class ParticlesExample extends PlatformerGameScene
	{
		public function ParticlesExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/particlesExample/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			particleExamples();
		}
		
		//////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////// PARTICLES & EMITTERS ////////////////////////////////////
		//////////////////////////////////////////////////////////////////////////////////////////////
		/**
		 * We use the Flint particle system to create particles within the framework.
		 * Flint can take a little while to fully grasp, but once you understand its ins and outs
		 * you can creating complex particle behavior with only a few lines of code.
		 */
		
		private function particleExamples():void
		{
			// Example 1 : Particle Basics
			basicEmitter();
			
			// Example 2 : Fint Initializer & Actions
			customEmitter();

			// Example 3 : BitmapImage, make Bitmap particles from a shared BitmapData.
			bitmapEmitter();
			//
			// Example 4 : BitmapRenderer, an emitter that draws the particles to a single Bitmap.
			bitmapRendererEmitter();
			//bitmapRendererEmitter2();
			
			// Example 5 : Using External Assets as Particles
			externalAssetEmitter()
			
			// Example 6 : Screen wide Particles
			viewportEmitter()

		}

		/**
		 * Example 1 : Particle Basics
		 * 
		 * In order for Flint to work with the Ash framework we had to create a wrapper,
		 * that uses the frameworks update loop and takes into account pausing.
		 * Partiicles are wrapper in an emitter entity, which we'll create in this example.
		 */
		private function basicEmitter():void
		{
			/**
			 * We use the EmitterCreator to create the emitter Entity and it's necessary components.
			 * EmitterCreator has only one static function, create(), which is creates the netity.
			 * Let's look it's method description:
				 * 
				 *  Creates an emitter entity.
				 * @param	group
				 * @param	container - display object emitter is contained within
				 * @param	emitter2D - Emitter class that emitter entity will use.
				 * @param	offsetX - x offset from parentEntity's origin.
				 * @param	offsetY - y offset from parentEntity's origin.
				 * @param	parentEntity - character that emitter is associated with.
				 * @param	id - name the particular emitter, ids must be unique within parentEntity.
				 * @param	follow - if specified, the spatial that that emitter should move with ( usually a joint ) 
				 * @return
			 */
			
			// Let's step through each of it's parameters
			
			// group refers to the group the entiy will be added to, normally the current Scene
			var group:Group = this;
			
			/**
			 * container - The display object that will contain the particles.
			 * This can be the _hitContainer, or any clip you specify.
			 * Remember that the particles will be contained within the clip, and will inherit its behavior.
			 */
			var container:DisplayObjectContainer = super._hitContainer;
			
			/**
			 * emitter - this is where we add the Flint specific class, which must inherit from Emitter2D.
			 * This is a class that must be created, look in the particles folder with the examle folder:
				 * 
				 * game.scenes.testIsland.particleTest.particles/ParticleExample1
				 * 
			 * We need to call the init function of the emitter to set it's behavior
			 * We'll look at how to define the particle behavior later. 
			 */
			var emitter:ParticleExample1 = new ParticleExample1();
			emitter.init();
			
			/**
			 * offsetX & offsetY - These are what you would think they are, they offset the emitter position.
			 * Without these the emitter would be place at 0,0 within the _hitContainer.
			 * We use offsets to place the emitter to where we can see it.
			 */
			var offsetX:int = 500;
			var offsetY:int = 800;
			
			/**
			 * There are more optional paramters for more sophisticated functions, 
			 * but let's run with what we've got so far.
			 */
			
			var basicEmitter:Entity = EmitterCreator.create( group, container, emitter, offsetX, offsetY );
			
			/**
			 * Viola, we have made a particle emitter.
			 * Let's create another emitter next to it using a minimum of code. 
			 */
			var emitter1:ParticleExample1 = new ParticleExample1();
			emitter1.init();
			EmitterCreator.create( this, super._hitContainer, emitter1, 600, 800 );
			
			/**
			 * If your emitter doesn't need any external parameters for its init function 
			 * then you can have the emitter call init() within its constructor.
			 * You could then get your emitter creation to a single line:
			 * 
				 * 
				 * EmitterCreator.create( this, super._hitContainer, new SimpleEmitter(), 600, 800 );
				 * 
			 */
		}
		
		/**
		 * Example 2 : Flint Initializers and Actions
		 * 
		 * In this example we are going to create a custom Emitter2D
		 * and explore some of the basic parts.
		 */
		private function customEmitter():void
		{
			/**
			 * Flint has a lot of similarities to the Ash framework,
			 * in fact it was designed by the same guy, Richard Lord. 
			 * It also uses the idea of composition to create functionality,
			 * and putting those components into 'empty' containers.
			 */
			
			var emitter:Emitter2D = new Emitter2D();
			/**
			 * We create a basic Emitter2D that we will further define.
			 * You can sort of think of an Emitter2D as an Entity.
			 * It is just something that can hold 'components'.
			 * Those components then get acted on by systems.
			 *
			 * Ever Emitter2D requires some basics to get started.
			 * Many are optional, but the counter var must be defined.
			 * The counter determines the rate at which particles are created.
			 */  
			
			emitter.counter = new Random( 10, 30 );
			/**
			 * We create a Random counter and pass it a minRate & maxRate.
			 * A counter's rate is the number of particles per second.
			 * So here we have defined a variable rate between 10 to 30 particles per second. 
			 * 
			 * There are a number of different available Counter classes.
			 * Here is a list with brief desciptions of the basics:
			  * 
			  * Blast - emit particles all at once.
			  * Pulse - emit groups of particles at a regular interval.
			  * Random - emit continuously at a variable random rate between two limits.
			  * SineCounter - emit continuiously at a rate according to a sine wave.
			  * Steady - emit continuiously at a steady rate.
			  * 
		     * KeyDownCounter, PerformanceAdjusted, TimePeriod, & ZeroCounter are also available.
			 * Learn more about each: org.flintparticles.common.counters  
			 */
			
			/**
			 * Initializers 
			 * The next step is to define the 'start' state for the particles.
			 * We add Initializer classes to accomplish this.
			 * There are many different Initializers for different attributes.
			 * We'll look at a few of the basics
			 */
			
			emitter.addInitializer( new ImageClass( Dot, [2, 0xFF00FF], true ) );
			/**
			 * Here we're using the ImageClass to define what our particles look like.
			 * The parameters can be a litle mysterious so let's look at their definitions:
				 *
				 * @param imageClass The class to use when creating the particles' DisplayObjects.
				 * @param parameters The parameters to pass to the constructor for the image class.
				 * @param usePool Indicates whether particles should be reused when a particle dies.
				 * @param fillPool Indicates how many particles to create immediately in the pool, to
				 * avoid creating them when the particle effect is running.
				 * 
			 * So to create an ImageClass we need to pass it a class that creates the displayObject.
			 * Here we are using Dot, which is supplied with in the Flint classes.
			 * If we look at the Dot class we see that it extends Shape and draws a circle.
			 * All included are:
				 * 
				 * Dot
				 * Ellipse
				 * Line
				 * RadialDot
				 * Rect
				 * Ring 
				 * Star
				 * 
			 *  Nothing prevents us creating our own custom class here as well.
			 * 
			 * The second parameter is juts an Array of the possible parameters for the first parameter.
			 * See if we look at the Dot class constructor we see this:
				 * 
				 * public function Dot( radius:Number = 1, color:uint = 0xFFFFFF, bm:String = "normal" )
				 * 
			 * So our our second parameter, [2, 0xFF00FF], starts to make more sense.
			 * The 2 is defining the Dot classes radius, and 0xFF00FF defines its color.
			 * 
			 * The last parameter refers to particle pooling, which should be set to true.
			 */
			
			emitter.addInitializer( new Position( new DiscZone( null, 20 )));
			emitter.addInitializer( new Velocity( new LineZone( new Point( -50, -60 ), new Point(50, -60))));
			/**
			 * Next we want to define the particle starting position and starting velocity
			 * We create a new Position class and Velocity classes and add them as initializers
			 * But then we pass in DiscZone & LineZone as their parameters, and things start to look crazy.
			 */
			
			/**
			 * What is a Zones and how to they work?
			 * 
			 * Using zones is likely th emost confusing aspect of Flint, so let's go over them.
			 * Zones are what they sound like, class that define an area.
			 * There are many different zones, though usually you'll just use the first :
				 * 
				 * PointZone - defines a single point.
				 * LineZone - defines a line with a start and end point.
				 * RectangleZone - defines a rectangular are.
				 * DiscZone - defines a circular area, but can also define a doughnut-type area
				 * DiscSectorZone - defines a slice of a donut-type area
				 * EllipseZone - defines an elliptical or oval area.
				 * 
				 * DisplayObjectZone - uses a DisplayObject to define an area.
				 * BitmapDataZone - uses a BitmapData to define an area.
				 * GreyscaleZone - uses a BitmapData to define an area, using the pixel value as a weight.
				 * MultiZone - combine zones together.
			 * 
			 * The idea of the zone is straightforward, but how they're used is at first a little nonintuitive.
			 * 
			 * Let's look at how Position uses the DiscZone.  This is the DiscZone constructor:
				 * 
				 * public function DiscZone( center:Point = null, outerRadius:Number = 0, innerRadius:Number = 0 )
				 * 
			 * So the first parameter defines the center of circle, since we left it null, it will default to (0,0).
			 * The next parameter is the outerRadius, which we set at 50, we want a circle with a radius of 20.
			 * We didn't include an innerRadius parameter, so have create a circular area with a radius of 20.
			 * 
			 * Position uses the zone when emitting a particle, by choose a random Point within the zone.
			 * So when a particle is emitted it's position will be defined by the zone that was passed to Postion.
			 * When using zones with Position things are straight forward, the position is a Point retrieve from within the area.
			 * 
			 * Let's look at Velocty now and see how it uses zone.
			 * For Velocity we used a LineZone, whose constructor looks like this:
				 * 
				 * public function LineZone( start:Point = null, end:Point = null )
				 * 
			 * So a LinZone requires a start point and an end point.  
			 * But what does a zone have to do with velocity?
			 * Well, here Flint uses the method we saw with Position, it choose a random Point within its area.
			 * When we created our LineZone we gave it a start Point of (-50, -60) and an end Point of (50,-60).
			 * 
			 * So when Velocity request a random 'position' from the LineZone the x will be between -50 to 50, and the y will be -60.
			 * This 'position' gets returned as Point, so we might get something like (35,-60).
			 * What the Velocity does with this Point is actually apply it to the particle's velocity. 
			 * So with a 'position' of (35,-60) the particle gets a starting x velocity of 35, and y velocy of -60.
			 * 
			 * The mental jump here is thinking about an area providing a range of values contained within Points.
			 * The x & y values within the Point can be used for position, but also velocity.
			 */
			
			
			emitter.addInitializer( new Lifetime( 1, 1.25 ) );
			/**
			 * The last initializer we use is Lifetime, which determines how long th eparticle is 'alive':
				 * 
				 * public function Lifetime( minLifetime:Number = Number.MAX_VALUE, maxLifetime:Number = NaN )
				 * 
			 * We can set just the minimum minLifetime, or can set both to create a range for randomization. 
			 */
			
			/**
			 * That's it for our Initializers.  We defined our counter, chose a display, & set position, velocity, and lifetime.
			 * These all effect how the particle is initially create. 
			 * Now we will add Actions that determine how the particle will behave once it has been brough tot life.
			 */
			
			emitter.addAction( new Age( Quadratic.easeIn ) );
			/**
			 * The first thing we do is add the Age Action.  This makes our particle lose 'energy' and eventually 'die'.
			 * We can also define how the energy decreases, by default the aging is linear, 
			 * but we can pass an interpolation Function to customize how the energy decreases.
			 * We've passed Quadratic.easeIn to define how Age will decrease the particle's 'energy'.
			 * 
			 * TwoWay lerp will start and end at the same place. The end param is the start and end points of the transition.
			 * The start param is the middle transition peak.
			 */
			
			emitter.addAction( new Move() );
			/**
			 * We add the Move Action to make our particles move.
			 */
			
			emitter.addAction( new Accelerate( 0, 200 ) );
			/**
			 * Finally we add an Accelerate Action, which will apply itself to the particles each update:
				 * 
				 * public function Accelerate( accelerationX:Number = 0, accelerationY:Number = 0 )
				 * 
			 * We assign accelerationX to 0, so the x velocity will not be effected.
			 * We assign accelerationY to 200, so that our particles will accelerate downwards.
			 * In essence we have used applied 'gravity' to the particles, making subject to a downward velocity each update.
			 */
			
			/**
			 * That's it!  We've defined out emitter.
			 * Now let's add it to the scene.
			 */
			
			EmitterCreator.create( this, super._hitContainer, emitter, 800, 800 );
			/**
			 * This time we don't need an init() since we actually made our emitter within our function.
			 * Below is another version with some additional Initializers and Actions.
			 */
			
			var emitter2:Emitter2D = new Emitter2D();
			
			emitter2.counter = new Steady( 10 );
			emitter2.addInitializer( new ImageClass( Star, [8], true ) );
			// NOTE: ColorInit requires an AlphoInit in order for it to appear
			emitter2.addInitializer( new ColorInit(0x990011, 0x4400FF) );	// initialize from a color range
			//emitter2.addInitializer( new ScaleImageInit( 1, 3) );			// initialize from a scale range
			emitter2.addInitializer( new AlphaInit( 1, 2) );				// initialize from a alpha range
			emitter2.addInitializer( new Position( new RectangleZone( -25,-25,25,25)));
			emitter2.addInitializer( new Velocity( new LineZone( new Point( -50, -120 ), new Point(50, -80))));
			emitter2.addInitializer( new Lifetime( 1, 2 ) );
			
			emitter2.addAction( new Age( Quadratic.easeIn ) );
			emitter2.addAction( new Move() );
			emitter2.addAction( new Accelerate( 0, 200 ) );
			emitter2.addAction( new RandomDrift( 15, 15 ) );				// add a random drift
			emitter2.addAction( new Fade() );								// cause alpha to decrease with age
			emitter2.addAction( new ScaleImage( 1, .2) );					// cause scale to decrease with age
			//emitter2.addAction( new ColorChange( 0x990011, 0xFFFFFF ));	// cause color to shift with age
			
			EmitterCreator.create( this, super._hitContainer, emitter2, 900, 800 );
			
			/**
			 * Try changing parameters & commenting out certain Actions to create a different effect.
			 * Getting the right effect can take some time and tweaking. 
			 * We hope to have a standalone Particle Editor eventually that will expediate this process.
			 * 
			 * You'll notice that some Actions will override Initializers.
			 * For example the ScaleImage Action will override the ScaleImageInit Initializer, 
			 * and the ColorChange Action will override the ColorInit Initializer.
			 * Just be aware of this, as it can lead to confusing particles behavior.
			 */
			
		}

		/**
		 * Example 4 : Using shared BitmapData
		 * 
		 * In this example use a single BitmapData to create our particles from.
		 * In most cases where you need an external asset, as in example 3, you want to use this method.
		 * If your swf needs to stay a swift because it is animating, then ExternalImage (example 6) would be necessary,
		 * but for images that will be static the BtmapImage is probably the way to go.
		 */
		private function bitmapEmitter():void
		{
			// the shard.swf asset is included in the scene's asset tag so it's already load, so we just retrive it.
			var shardAsset:MovieClip = super.getAsset( "shard.swf") as MovieClip; 
			// we get its bitmapData using DisplayUtils 
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(shardAsset);
			
			// create the emitter
			var bitmapEmitter:Emitter2D = new Emitter2D();
			bitmapEmitter.counter = new Pulse( 3, 20 );
			
			// Instead of the usual ImageClass, we use BitmapImage and pass it the BitmapData we created.
			bitmapEmitter.addInitializer( new BitmapImage(bitmapData) );
			bitmapEmitter.addInitializer( new Lifetime( 12, 15 ) );;
			bitmapEmitter.addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 200, -10 ) ) );
			bitmapEmitter.addInitializer( new ScaleImageInit( 0.1, .7) );
			
			bitmapEmitter.addAction( new Age( ) );
			bitmapEmitter.addAction( new Move( ) );
			bitmapEmitter.addAction( new RotateToDirection() );
			bitmapEmitter.addAction( new Accelerate( 0, 620 ) );
			
			var emitterEntity:Entity = EmitterCreator.create( this, super._hitContainer, bitmapEmitter, 1100, 700 );
			
		}

		/**
		 * Example 5 : Creating an particles using a bitmap renderer.
		 * 
		 * In this example we use a different kind of emitter, where teh particles are drawn to a bitmap on each update.
		 * This approach is good for emitters that may have a high frequency of particles, but occupy small area.
		 * NOTE :: This approach actually proves to be rather expensive, use SharedBitmap instead if possible.
		 */
		private function bitmapRendererEmitter():void
		{
			// first we create an emitter
			var emitter:Emitter2D = new Emitter2D(); 
			var count:uint = 500;
			emitter.counter = new Random(count/10, count);
			
			// for this emitter we want use a blend mode, this is less expensive with a bitmapRenderer
			//var blend_mode:String = BlendMode.ADD;
			var blend_mode:String = BlendMode.NORMAL;
			var image_weights:Array = [0.5, 0.25, 0.15, 0.10];

			// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
			//emitter.addInitializer( new SharedImages([new Dot(4, 0xFF1878a8, blend_mode), new Dot(3, 0xFF78c0d8, blend_mode), new Dot(1, 0xFFa8d8f0, blend_mode), new Dot(1, 0xFFc0f0f0, blend_mode)], image_weights));
			emitter.addInitializer( new SharedImage(new Dot(4, 0xFF1878a8, blend_mode)));
			emitter.addInitializer( new Position( new PointZone( new Point(0, 0) ) ) );
			emitter.addInitializer( new Velocity( new DiscSectorZone(new Point(0, 0), 200, 100, 0, Math.PI/12  )));
			emitter.addInitializer( new Lifetime( 0.25, 1.0 ) );
			
			emitter.addAction( new Age() );
			emitter.addAction( new Move() );
			emitter.addAction( new ScaleAll(1, 0) );
			emitter.addAction( new RandomDrift( 150, 150 ) );
			emitter.addAction( new Accelerate(0, 500) );
			
			// for BitmapRenderer we need to define the size of the bitmap that the particles will be drawn to.
			// we add a little buffer to the rect so that particles don't get clipped.
			var x_offset:uint = 1300;
			var y_offset:uint = 800;
			var buffer:uint = 10;
			var canvas_rect:Rectangle = new Rectangle(x_offset - buffer, y_offset - buffer, 200, 250);
			
			var renderer:BitmapRenderer = new BitmapRenderer(canvas_rect, false);
			//renderer.clearBetweenFrames = false;
			var emitterEntity:Entity = EmitterCreator.createBitmapRenderer(this, super._hitContainer, renderer, emitter, x_offset, y_offset, null, "", null); 
			//renderer.filters = [new GlowFilter(0xFFFFFF, 1.0, 5, 5, 10, 3, false, false)]
		}
		
		private function bitmapRendererEmitter2():void
		{
			// first we create an emitter
			var emitter:Emitter2D = new Emitter2D(); 
			var count:uint = 500;
			emitter.counter = new Random(count/10, count);
			
			// for this emitter we want use a blend mode, this is less expensive with a bitmapRenderer
			//var blend_mode:String = BlendMode.ADD;
			//var image_weights:Array = [0.5, 0.25, 0.15, 0.10];
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot(4, 0xFF1878a8));
			
			// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
			emitter.addInitializer( new BitmapImage(bitmapData) );
			emitter.addInitializer( new Position( new PointZone( new Point(0, 0) ) ) );
			emitter.addInitializer( new Velocity( new DiscSectorZone(new Point(0, 0), 200, 100, 0, Math.PI/12  )));
			emitter.addInitializer( new Lifetime( 0.25, 1.0 ) );
			
			emitter.addAction( new Age() );
			emitter.addAction( new Move() );
			emitter.addAction( new ScaleAll(1, 0) );
			emitter.addAction( new RandomDrift( 150, 150 ) );
			emitter.addAction( new Accelerate(0, 500) );
			
			// for BitmapRenderer we need to define the size of the bitmap that the particles will be drawn to.
			// we add a little buffer to the rect so that particles don't get clipped.
			var x_offset:uint = 1500;
			var y_offset:uint = 800;
			
			var emitterEntity:Entity = EmitterCreator.create( this, super._hitContainer, emitter, x_offset, y_offset );
		}
		
		/**
		 * Example 6 : Using external assets as particles
		 * 
		 * In this example we use an external asset as our particle.
		 * We have also specified an array of external assets.
		 * When a new particle is created its asset will be randomly choose the array we provided.
		 * Usually we only want use this if the particle needs to be a swf, say it has an timeline animation.
		 * In most cases were external swfs are necessary we'll want to use the BitmapImage (example 4).
		 */
		private function externalAssetEmitter():void
		{
			var assetEmitter:Emitter2D = new Emitter2D();
			var colors:Array = [0xFF3E3E, 0xFF9900, 0xFBF404, 0x66FF00, 0x0D91F2, 0xA476D1, 0xEF0065];
			assetEmitter.counter = new Pulse( 2, 5 );
			
			assetEmitter.addInitializer( new ChooseInitializer([new ExternalImage("assets/particles/skull.swf")]));
			assetEmitter.addInitializer( new Lifetime( 12, 30 ) );;
			assetEmitter.addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 200, 10, -Math.PI, 0 ) ) );
			assetEmitter.addInitializer( new Position( new DiscZone( new Point( 0, 0 ),4 ) ) );
			assetEmitter.addInitializer( new Rotation( 0, Math.PI * 2 ));
			assetEmitter.addInitializer( new ScaleImageInit( 0.4, .5) );

			assetEmitter.addAction( new Age( ) );
			assetEmitter.addAction( new Move( ) );
			assetEmitter.addAction( new Accelerate( 0, 320 ) );
			assetEmitter.addAction( new LinearDrag( 2 ) );
			assetEmitter.addAction( new AntiGravity(100, 100, 100, 4 ));
			assetEmitter.addAction( new CircularAcceleration(100, 3) );
			assetEmitter.addAction( new RandomDrift( 300 ) );
			
			EmitterCreator.create( this, super._hitContainer, assetEmitter, 1500, 700 );
		}
		
		/**
		 * Example 7 : Creating scene sized emitters
		 * 
		 * In this example we want an effect that will fill the scene.
		 * NOTE :: Other classes have been written that better manage scene wide effects, best to look into thos efirst.
		 */
		private function viewportEmitter():void
		{
			// lock input
			//SceneUtil.lockInput( this );
			
			var viewportEmitter:Emitter2D = new Emitter2D();
			var box:Rectangle = new Rectangle( 0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			
			viewportEmitter.counter = new Random( 1, 5 );
			viewportEmitter.addInitializer(new ImageClass(Blob, [2, 0xFFFFFF], true));
			viewportEmitter.addInitializer(new Position(new RectangleZone(box.left, box.top, box.right, 1)));
			viewportEmitter.addInitializer(new Velocity(new LineZone(new Point(-100, 50), new Point(100, 200))));
			viewportEmitter.addInitializer(new ScaleImageInit(.75, 1.25));
			
			viewportEmitter.addAction(new Move());
			viewportEmitter.addAction(new RandomDrift(300, -25));
			viewportEmitter.addAction(new DeathZone(new RectangleZone(box.left - box.width, box.top - box.height, box.right * 2, box.bottom * 2), true));
			
			EmitterCreator.create( this, super.overlayContainer, viewportEmitter );
		}
		
		private var _showerEntity:Entity;
	}
}