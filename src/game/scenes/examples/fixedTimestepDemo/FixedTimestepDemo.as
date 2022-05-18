package game.scenes.examples.fixedTimestepDemo{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.components.motion.SceneObjectMotion;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.examples.fixedTimestepDemo.components.FixedTimeDemo;
	import game.scenes.examples.fixedTimestepDemo.components.VariableTimeDemo;
	import game.scenes.examples.fixedTimestepDemo.systems.FixedTimeDemoSystem;
	import game.scenes.examples.fixedTimestepDemo.systems.VariableTimeDemoSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	/**
	 * Here are some steps to follow to run through the demo:

		1.  Upon loading the scene you'll see two counters advancing, one that is being updated by a fixed time system and one that is updating in a variable-time system.  
		 		The fixed-time system is set to run at 30 fps, so it is advancing at about half the rate of the variable-time system (assuming the scene is at 60 fps).
		
		2.  If you click the 'cycle fps' button you can cycle through different framerates for the game.  Notice that if you set the scene fps to 30 that the fixed time 
		 		and variable time counters advance at about the same rate.
		
		3.  If you set the framerate to less than 30 fps the fixed time counter will still advance at the same rate, just in bigger steps.  Setting the fps to 5 or 10 
		 		makes this clearer.  The variable time system's updates will match the current framerate, so the lower the framerate the slower it will advance.
		
		4.  Return the framerate to 60 fps and click 'launch 50 boxes'.  This will cause 50 box wireframes to be launched and bounce along the platforms.  
		 		If the scene is running on fixed time (the green light next to the 'fixed timestep' button should be ON) then you should notice them all land in the exact same 
		 		spot on the small green platform on the right side of the scene.
		
		5. Now hit the 'fixed timestep' button so the green light next to it is OFF.  Trying hitting the 'launch 50 boxes' button again.  
		 		This time, notice that all boxes don't end up in the same spot.  Depending on your fps they may be more or less consistent.
		
		6.  Try clicking the 'erratic fps' button.  If 'fixed time' is off, the boxes will be even more scattered around due to the inconsistency of the update time.  
		 		If 'fixed time' is on, however, they should still all end up in the same spot on the small green platform no matter how bad the framerate is.
		
		
		Any new Systems created that involve motion or collisions should use fixed time.  You enable this in the system in the system constructor like this:
		
		        public function MotionSystem()
				{
					super.fixedTimestep = FixedTimestep.MOTION_TIME;  // this sets the fixed timestep
					super.linkedUpdate = FixedTimestep.MOTION_LINK;   // link this system to all other motion systems so they update in sync
				}
		
		Animation also uses fixed time so that it is always at 32 fps.  New animation systems should be setup like this:
		
		        public function TimelineControlSystem()
				{
					super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
					super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
				}

	 */
	
	public class FixedTimestepDemo extends PlatformerGameScene
	{
		public function FixedTimestepDemo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/fixedTimestepDemo/";
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
			
			createButtons();
			
			_boxGroup = new Group();
			super.addChildGroup(_boxGroup);
			
			/**
			 * Add two entities with counters that increment on every update.  The fixed time counter will always increment the same number of times in a given
			 * time period, where the variable time counter will change based on framerate.
			 */
			super.addSystem(new FixedTimeDemoSystem(), SystemPriorities.update);
			super.addSystem(new VariableTimeDemoSystem(), SystemPriorities.update);
			super.addSystem(new SceneObjectMotionSystem(), SystemPriorities.moveComplete);
			
			var entity:Entity = new Entity();
			entity.add(new Display(MovieClip(super._hitContainer).fixedTimeOutput));
			entity.add(new FixedTimeDemo());
			entity.add(new Id("fixedCounter"));
			super.addEntity(entity);
			
			entity = new Entity();
			entity.add(new Display(MovieClip(super._hitContainer).variableTimeOutput));
			entity.add(new VariableTimeDemo());
			entity.add(new Id("variableCounter"));
			super.addEntity(entity);
		}
		
		private function createButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 16, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).timestepToggleButton, this, handleToggleTimestep );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).timestepToggleButton, "Fixed Timestep", labelFormat, ButtonCreator.ORIENT_CENTERED);
			MovieClip(super._hitContainer).timestepToggleLight.gotoAndStop("on");
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).launchBoxButton, this, handleLaunchBox );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).launchBoxButton, "Launch Box", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).launch50BoxButton, this, handleLaunch50Box );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).launch50BoxButton, "Launch 50 Boxes", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).framerateToggleButton, this, handleCycleFPS );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).framerateToggleButton, "Cycle FPS", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).erraticFPSToggleButton, this, handleErraticFPS );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).erraticFPSToggleButton, "Erratic FPS", labelFormat, ButtonCreator.ORIENT_CENTERED);
			MovieClip(super._hitContainer).erraticFPSToggleLight.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).resetTimerButton, this, handleResetTimer );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).resetTimerButton, "Reset Counters", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		
		private var _erraticFPS:Boolean = false;
		
		private function handleResetTimer(...args):void
		{
			FixedTimeDemo(super.getEntityById("fixedCounter").get(FixedTimeDemo)).totalUpdates = 0;
			VariableTimeDemo(super.getEntityById("variableCounter").get(VariableTimeDemo)).totalUpdates = 0;
		}
		
		private function handleErraticFPS(...args):void
		{
			_erraticFPS = !_erraticFPS;
			
			var clip:MovieClip = MovieClip(super._hitContainer).erraticFPSToggleLight;
			
			if(_erraticFPS)
			{
				clip.gotoAndStop("on");
				
				if(_erraticFPSTimer == null) 
				{ 
					_erraticFPSTimer = SceneUtil.addTimedEvent( this, new TimedEvent( .1, 0, pickRandomFPS, true) ); 
				}
				else
				{
					_erraticFPSTimer.start();
				}
			}
			else
			{
				clip.gotoAndStop("off");
				_erraticFPSTimer.stop();
			}
		}
		
		private function handleLaunchBox(button:Entity):void
		{
			makeBox();
		}
		
		private function handleToggleTimestep(button:Entity):void
		{
			super.systemManager.updateComplete.addOnce(toggleTimestep);
		}
		
		private function handleLaunch50Box(button:Entity):void
		{
			super.removeGroup(_boxGroup, true);
			
			super.systemManager.updateComplete.addOnce(startBoxLaunch);
		}
		
		private function startBoxLaunch():void
		{
			_boxGroup = new Group();
			super.addChildGroup(_boxGroup);
			SceneUtil.addTimedEvent( this, new TimedEvent( .1, 50, makeBox, true) );
		}
		
		private function handleCycleFPS(button:Entity):void
		{
			if(_erraticFPS) { handleErraticFPS(); }
			
			var fps:Array = [60, 30, 20, 10, 5];
			
			_fpsIndex++;
			
			if(_fpsIndex == fps.length)
			{
				_fpsIndex = 0;
			}
						
			MovieClip(super._hitContainer).framerateToggleText.text = fps[_fpsIndex];
			
			super.shellApi.setFPS(fps[_fpsIndex]);
		}
		
		private function toggleTimestep():void
		{
			super.systemManager.fixedTimestepUpdates = !super.systemManager.fixedTimestepUpdates;
			
			var clip:MovieClip = MovieClip(super._hitContainer).timestepToggleLight;
			
			if(super.systemManager.fixedTimestepUpdates)
			{
				clip.gotoAndStop("on");
			}
			else
			{
				clip.gotoAndStop("off");
			}
		}
		
		private function makeBox():void
		{
			loadBox(460, 3800);
		}
		
		private function loadBox(x:Number, y:Number):void
		{
			super.loadFile("box.swf", boxLoaded, x, y);
		}
		
		private function boxLoaded(clip:MovieClip, x:Number, y:Number):void
		{
			if(!super.systemManager.updating)
			{
				createBox(clip, x, y);
			}
			else
			{
				super.systemManager.updateComplete.addOnce(Command.create(createBox, clip, x, y));
			}
		}
		
		private function createBox(clip:MovieClip, x:Number, y:Number):void
		{
			super._hitContainer.addChild(clip);
			var box:Entity = new Entity();
			var motion:Motion = new Motion();

			motion.velocity = new Point(350, -800);
			motion.friction 	= new Point(400, 0);
			motion.maxVelocity 	= new Point(1000, 1000);
			motion.minVelocity 	= new Point(0, 0);
			motion.acceleration = new Point(0, MotionUtils.GRAVITY);
			motion.restVelocity = 100;
			
			box.add(new Spatial(x, y));
			box.add(new Display(clip));
			box.add(motion);
			box.add(new Edge(-25, -25, 50, 50));
			box.add(new PlatformCollider());
			box.add(new SceneCollider());
			box.add(new BitmapCollider());
			box.add(new CurrentHit());
			box.add(new WaterCollider());
			box.add(new Id("box"));
			box.add(new MotionBounds(super.sceneData.bounds));
			
			var sceneObjectMotion:SceneObjectMotion;
			sceneObjectMotion = new SceneObjectMotion();
			sceneObjectMotion.rotateByPlatform = false;
			sceneObjectMotion.rotateByVelocity = false;
			sceneObjectMotion.platformFriction = 1500;
			box.add(sceneObjectMotion);
			
			_boxGroup.addEntity(box);
		} 
		
		private function pickRandomFPS():void
		{
			var randomFPS:Number = Utils.randInRange(5, 60);
			MovieClip(super._hitContainer).framerateToggleText.text = randomFPS;
			
			super.shellApi.setFPS(randomFPS);
		}
		
		private var _fpsIndex:int = 0;
		private var _erraticFPSTimer:TimedEvent;
		private var _boxGroup:Group;
	}
}