package game.scenes.examples.inputExample{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.input.Input;
	import game.components.motion.FollowTarget;
	import game.components.motion.RadiusControl;
	import game.components.motion.RotateControl;
	import game.components.motion.TargetSpatial;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.RadiusToTargetSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class InputExample extends PlatformerGameScene
	{
		public function InputExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/inputExample/";
			
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
			setupExamples();
			
			super.loaded();
		}
		
		private function setupExamples():void
		{
			var btnClip:MovieClip;
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			listenForInput();
			btnClip = MovieClip(super._hitContainer).btn1;
			ButtonCreator.createButtonEntity( btnClip, this);
			ButtonCreator.addLabel( btnClip, "Input Down", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_inputDownLight = MovieClip(super._hitContainer).lightGreen1;	// simple on/off movieclip to demonstrate example
			_inputDownLight.gotoAndStop(1);
			
			btnClip = MovieClip(super._hitContainer).btn2;
			ButtonCreator.createButtonEntity( btnClip, this, lockInput );
			ButtonCreator.addLabel( btnClip, "Lock Input", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_inputLockLight = MovieClip(super._hitContainer).lightGreen2;	// simple on/off movieclip to demonstrate example
			_inputLockLight.gotoAndStop(1);
			
			btnClip = MovieClip(super._hitContainer).btn3;
			ButtonCreator.createButtonEntity( btnClip, this, simpleCursor );
			ButtonCreator.addLabel( btnClip, "Simple Cursor", labelFormat, ButtonCreator.ORIENT_CENTERED);

			targetingInput();
			
			createDraggableEntity();
			
			btnClip = MovieClip(super._hitContainer).btn4;
			ButtonCreator.createButtonEntity( btnClip, this, eyesFollowTarget );
			ButtonCreator.addLabel( btnClip, "Eyes Follow", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		
		
		/**
		 * Example 1: Listen for Input
		 * 
		 * To handle general inputs within scenes an input entity is created.
		 * In this example we will see how to access that entity and listen for its input.
		 * 
		 * To allow for general mouse clicks/screen presses on the screen
		 * an input entity is created as part of the Scene creation.
		 * The Scene calls SceneUtil.createInputEntity to create that input entity.
			 * 
			 * SceneUtil.createInputEntity( inputContainer, group)
			 * 
		 * This returns an Entity with Spatial, Input, & FollowInput components.
		 * The inputContainer that the Scene passes is a DisplayObject the size of the scene,
		 * so inputs are registered anywhere in the scene.
		 * Input can be blocked by clips within the interaction layer,
		 * if their mouseEnabled has not been set to false, such is the case for doors and buttons.
		 */
		private function listenForInput():void
		{
			// So let's get the inputEntity, we can get this directly from shellApi
			var inputEntity:Entity = shellApi.inputEntity;
			/**
			 * This Entity directly follows the input( the mouse for web, touch for tablet )
			 * and registers all screen clicks.
			 */
			
			// Now let's add handler for the input, to do that we get the Input component.
			// Then we add a handlers to the inputDown & inputUp Signals.
			var input:Input = inputEntity.get( Input ) as Input;
			input.inputDown.add( onInputDown );
			input.inputUp.add( onInputUp );
			
			/**
			 * There we have it, we can now add listen to screen clicks.
			 * An even quicker way to access the scene's input is this
			 */
			input = SceneUtil.getInput( this );
			 
			/** 
			 * NOTE :: The the Signal passes the Input component,
			 * so the handlers must take an Input as a parameter.
			 */
		}
		
		private function onInputDown( input:Input ):void
		{
			_inputDownLight.gotoAndStop(2);
		}
		
		private function onInputUp( input:Input ):void
		{
			_inputDownLight.gotoAndStop(1);
		}
		
		/**
		 * Example 2: Locking Input
		 * 
		 * Sometime we want to ignore or disable input.
		 * For this we have the Input component's lock paramter.
		 */
		private function lockInput( button:Entity ):void
		{
			// Locking the input is straightforward, get the scene's our Input & set lock to true;
			var input:Input = SceneUtil.getInput( this );
			input.lockInput = true;
			
			_inputLockLight.gotoAndStop(2);
			
			// You can also use the SceneUtil.lockInput method to achieve this in one line.
			SceneUtil.lockInput( this, true );

			/** 
			 * Since our input is now locked we can't presss another button to unlock it.
			 * So we set a timer to unlock input after a few seconds
			*/
			SceneUtil.addTimedEvent( this, new TimedEvent( 5, 1, unlockInput ) );
		}
		
		private function unlockInput():void
		{
			SceneUtil.lockInput( this, false );
			_inputLockLight.gotoAndStop(1);
		}
		
		/**
		 * Example 3: Follow Input
		 * 
		 * You can also use the input entity's Spatial as a target 
		 * so that other entities can follow it.
		 * This method is useful when you want to change the look of the cursor.
		 */
		private function simpleCursor( button:Entity ):void
		{
			if ( _cursorEntity == null )
			{
				// First we create an entity that will become our 'cursor'
				var clip:Sprite = new Sprite();
				clip.graphics.beginFill( 0xFF0000 );
				clip.graphics.drawCircle( 0, 0, 20 );
				clip.mouseEnabled = false;
				_cursorEntity = EntityUtils.createSpatialEntity( this, clip, super._hitContainer );
				
				/**
				 * Now let's make our new cursor Entity follow the input.
				 * To do these we create a FollowTarget component, 
				 * and make its target the input entity's Spatial, 
				 */
				var inputSpatial:Spatial = shellApi.inputEntity.get( Spatial ); 
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = inputSpatial;	// the Spatial that will be followed
				followTarget.rate = 1;	// rate of target following, 1 is highest causing 1:1 following 
				followTarget.applyCameraOffset = true;	// this needs be true with scenes using the camera 
				_cursorEntity.add( followTarget );
				
				/**
				 * That's it, we've create a simple 'cursor'. 
				 * If you want the cursor to ease toward the target, try adjusting the rate.
				 */
			}
			else
			{
				super.removeEntity( _cursorEntity );
				_cursorEntity = null;
			}
		}

		/**
		 * Example 4: Targeting Input
		 * 
		 * There are other ways to use the input entity as a target.
		 * This example demonstrates a few systems that can use 
		 * the input entity as a target to create common behavior.
		 */
		private function targetingInput():void
		{
			/**
			 * The RotateToControlSystem will rotate your entity to point torward it's TargetSpatial.
			 * Convenient for dials, guns, etc.
			 */
			var dialCenter:Point = new Point( 1600, 750 );
			
			var dialBase:Sprite = new Sprite();
			dialBase.graphics.beginFill( 0x000000 );
			dialBase.graphics.drawCircle( 0, 0, 10 );
			dialBase.mouseEnabled = false;
			dialBase.x = dialCenter.x;
			dialBase.y = dialCenter.y;
			super._hitContainer.addChild( dialBase );
			
			var dialClip:Sprite = new Sprite();
			dialClip.graphics.beginFill( 0xFFFFFF );
			dialClip.graphics.drawRect( 0, -3, 50, 6 );
			dialClip.mouseEnabled = false;
			
			var dialEntity:Entity = EntityUtils.createSpatialEntity( this, dialClip, super._hitContainer );
			EntityUtils.position( dialEntity, dialCenter.x, dialCenter.y );
			
			var targetSpatial:TargetSpatial =  new TargetSpatial( shellApi.inputEntity.get( Spatial ) );
			dialEntity.add( targetSpatial );
			
			var rotateControl:RotateControl = new RotateControl();
			rotateControl.targetInLocal = true;
			//rotateControl.setRange( -150, -30 );
			dialEntity.add( rotateControl );
			
			this.addSystem( new RotateToTargetSystem );
			
			/**
			 * The RadiusToControlSystem will position your entity radially torward it's TargetSpatial. 
			 * Convenient for pupils within eyes.
			 */
			var areaRadius:int = 30;
			var dotRadius:int = 10;
			var center:Point = new Point( 1700, 750 );
			 
			var circleArea:Sprite = new Sprite();
			circleArea.graphics.lineStyle( 1, 0x000000 );
			circleArea.graphics.beginFill( 0xFFFFFF );
			circleArea.graphics.drawCircle( 0, 0, areaRadius );
			circleArea.mouseEnabled = false;
			circleArea.x = center.x;
			circleArea.y = center.y;
			super._hitContainer.addChild( circleArea );
			
			var dot:Sprite = new Sprite();
			dot.graphics.beginFill( 0x000000 );
			dot.graphics.drawCircle( 0, 0, dotRadius );
			dot.mouseEnabled = false;
			var dotEntity:Entity = EntityUtils.createSpatialEntity( this, dot, super._hitContainer );
			
			// shorthand method for creating a TargetSpatial component
			dotEntity.add( EntityUtils.createTargetSpatial( shellApi.inputEntity ) );
			
			var radiusControl:RadiusControl = new RadiusControl( areaRadius - dotRadius / 2, center.x, center.y );
			radiusControl.cameraOffset = true;
			//radiusControl.setRange( 0, 180 );
			dotEntity.add( radiusControl );
			
			this.addSystem( new RadiusToTargetSystem );
			
			
			/**
			 * You can also specify ranges to limit the angle of possible movement.
			 * Try uncommneting the range setting to see what happens (they still need a little work)
			 */
			
		}
		
		/**
		 * Creates an entity that can be 'dragged' when clicked. - wrb
		 */
		private function createDraggableEntity():void
		{
			var cubeClip:MovieClip = MovieClip(super._hitContainer).companionCube;
			_cubeEntity = new Entity();
			
			_cubeEntity.add(new Display(cubeClip));
			_cubeEntity.add(new Spatial());
			
			// Add the necessary interactions.  We're using the 'down' and 'up' here.  A more robust way to capture the 'up' would be to use 
			//   Input(shellApi.inputEntity.get( Input )).inputUp which would detect a release over the whole screen, but adding it right to the 
			//   cube entity works fine as well.
			InteractionCreator.addToEntity(_cubeEntity, [InteractionCreator.DOWN, InteractionCreator.UP]);
			//  Add the necessary handlers.
			Interaction(_cubeEntity.get(Interaction)).down.add(draggableDown);
			Interaction(_cubeEntity.get(Interaction)).up.add(draggableUp);
			
			super.addEntity(_cubeEntity);
		}
		
		/**
		 * On a 'down' interaction, begin following the main input by adding the FollowTarget component.
		 */
		private function draggableDown(entity:Entity):void
		{
			var followTarget:FollowTarget = new FollowTarget();
			followTarget.target = shellApi.inputEntity.get( Spatial );	// the Spatial that will be followed, in this case the main input.
			followTarget.rate = 1;	// rate of target following, 1 is highest causing 1:1 following 
			followTarget.applyCameraOffset = true;	// this needs be true with scenes using the camera 
			entity.add( followTarget );
		}
		
		/**
		 * On an 'up' interaction, remove the FollowTarget component to stop following.
		 */
		private function draggableUp(entity:Entity):void
		{
			entity.remove(FollowTarget);
		}
		
		private function eyesFollowTarget( ...args ):void
		{
			if( !_eyesFollowingTarget )
			{
				CharUtils.eyesFollowTarget( super.player, _cubeEntity );
				_eyesFollowingTarget = true;
			}
			else
			{
				CharUtils.eyesFollowMouse( super.player );
				_eyesFollowingTarget = false;
			}
		}
		
		private var _inputDownLight:MovieClip;
		private var _inputLockLight:MovieClip;
		private var _cursorEntity:Entity
		private var _cubeEntity:Entity
		private var _eyesFollowingTarget:Boolean = false
	}
}