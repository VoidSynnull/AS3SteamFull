package game.scenes.examples.standaloneMotion
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	import engine.systems.TweenSystem;
	
	import game.components.input.Input;
	import game.components.motion.Edge;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	
	public class StandaloneMotion extends Scene
	{
		public function StandaloneMotion()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/standaloneMotion/";
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			// only need the background asset for this scene.  Not using scene.xml as we don't need the camera here.
			super.loadFiles(["background.swf"]);
		}
				
		// all assets ready
		override public function loaded():void
		{
			// scale the background to stretch to the screensize.  We're not using a camera here, so manipulating the scene art is done manually.
			var background:MovieClip = super.groupContainer.addChild(super.getAsset("background.swf", true)) as MovieClip;
			background.width = super.shellApi.viewportWidth;
			background.height = super.shellApi.viewportHeight;
			
			// for basic motion only render system and motion system are required.
			super.addSystem(new RenderSystem(), SystemPriorities.render);             // syncs an entity's Display component with its Spatial component
			super.addSystem(new MotionSystem(), SystemPriorities.move);	              // updates velocity based on acceleration, friction, and other forces acting on the entity.
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			super.addSystem(new TweenSystem(), SystemPriorities.update);              // provides standard Tweening functionality through system updates.
			super.addSystem(new InteractionSystem(), SystemPriorities.update);	      // updates interaction flags based on input.
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);           // provides additional motion on top of an entity's standard motion for movement based on math operations like sine waves.
			super.addSystem(new BoundsCheckSystem(), SystemPriorities.resolveCollisions);  // this system sets top,bottom,left and right flags when an entity leaves the bounds.  It also optionally repositions within bounds.
			super.addSystem(new SceneObjectMotionSystem(), SystemPriorities.update);         // this is a simple custom system made for this demo scene to demonstate modifying the ball physics based on its other components.
			
			// create tween example
			super.loadFile("ball.swf", ballLoaded, 400, 400, "tween");
			
			// create three balls with wave motion with their position in the sine wave offset.
			super.loadFile("ball3.swf", ballLoaded, super.shellApi.viewportWidth * .5 - 80, super.shellApi.viewportHeight * .5, "wave", 0);
			super.loadFile("ball3.swf", ballLoaded, super.shellApi.viewportWidth * .5, super.shellApi.viewportHeight * .5, "wave", Math.PI / 4);
			super.loadFile("ball3.swf", ballLoaded, super.shellApi.viewportWidth * .5 + 80, super.shellApi.viewportHeight * .5, "wave", Math.PI / 2);
			
			super.loadFile("ball.swf", ballLoaded, 400, 400, "follow");
			
			// create velocity example where the mouse is clicked.  shellApi.input is defined for every scene and serves as the input reference for mobile, tablet and desktop environments.
			Input(super.shellApi.inputEntity.get(Input)).inputDown.add(handleInputDown);
			
			super.loaded();
		}
		
		// loaded callback gets the loaded file as its first parameter, followed by any extra arguments passed in.
		private function ballLoaded(clip:MovieClip, x:Number, y:Number, motionType:String, wildcard:Number = 0):void
		{
			var entity:Entity = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = x;
			spatial.y = y;
			
			entity.add(spatial);
			entity.add(new Display(clip));
			
			super.groupContainer.addChild(clip);
			
			switch(motionType)
			{
				case "tween" :
					entity.add(new Tween());
					// start the tween movement cycle.  
					applyTween(entity);
				break;
				
				case "wave" :
					spatial.scale = 1.4;
					var waveMotionData:WaveMotionData = new WaveMotionData();
					var waveMotion:WaveMotion = new WaveMotion();
					
					// add a new WaveMotionData for each property on Spatial
					waveMotionData.property = "y";
					waveMotionData.magnitude = 20;
					waveMotionData.rate = .1;
					waveMotionData.radians = wildcard;
					waveMotionData.type = "sin";
					waveMotion.data.push(waveMotionData);
					
					waveMotionData = new WaveMotionData();
					waveMotionData.property = "scaleX";
					waveMotionData.magnitude = -.075;
					waveMotionData.rate = .1;
					waveMotionData.radians = wildcard;
					waveMotionData.type = "sin";
					waveMotion.data.push(waveMotionData);
										
					entity.add(waveMotion);
					
					// SpatialAddition applies the sine movement in addition to the current x/y of the entity.  This will let you make an entity move indepedently of its sine wave bobbing.
					entity.add(new SpatialAddition());
				break;
				
				case "velocity" :
					// setup the motion component with a min / max velocity, friction and acceleration values.
					var motion:Motion = new Motion();
					motion.friction 	= new Point(.1, 0);
					motion.maxVelocity 	= new Point(12 * 60, 16 * 60);
					motion.minVelocity 	= new Point(.5 * 60, 0);
					motion.acceleration = new Point(0, 700);
					motion.velocity = new Point(Math.random() * 600 - 300, -200 + Math.random() * -200);
					
					entity.add(motion);
					
					// this component defines an edge from the registration point of this entity.  This prevents the ball from going all the way to its center point when hitting bounds.
					var edge:Edge = new Edge();
					edge.unscaled.setTo(-25, -25, 50, 50);
					entity.add(edge);
					
					// This defines a rectangle to serve as the bounding box for this entity's motion.
					var boundsRect:Rectangle = new Rectangle(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight * .85);
					var motionBounds:MotionBounds = new MotionBounds(boundsRect);
					entity.add(motionBounds);
					
					// this is a custom component used in the new system built for this scene.  It handles simple bounding box collision reactions and rotates the ball based on its x velocity.
					entity.add(new SceneObjectMotion());
				break;
				
				case "follow" :
					
				break;
			}
			
			super.addEntity(entity);
		}
		
		private function applyTween(entity:Entity):void
		{
			var tween:Tween = entity.get(Tween);
			
			tween.to(entity.get(Spatial), 2, { x:(Math.random() * super.shellApi.viewportWidth),      // x and y target are picked anywhere within the screen
				 							   y:(Math.random() * super.shellApi.viewportHeight), 
											   ease:Sine.easeInOut,  								  // use the Sine.easeInOut type of transitions.  See more examples at http://www.greensock.com/tweenmax/
											   onComplete:applyTween,  								  // call this method again on the same entity when it completes.
											   onCompleteParams:[entity] });
		}
		
		private function handleInputDown(input:Input):void
		{
			super.loadFile("ball2.swf", ballLoaded, input.target.x, input.target.y, "velocity");
		}
	}
}