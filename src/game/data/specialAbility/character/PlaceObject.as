// Used by:
// Card 2693 using item limited_banana_peel (place banana peel hazard which avatar can slip on)
// Card 3054 using item flowerpower (place growing flower on ground)
// Card 3129 using item procket (plant rocket on ground and it soars up and explodes)

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Place;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.character.objects.Daisy;
	import game.data.specialAbility.character.objects.Firework;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	
	/**
	 * Place object on ground
	 * 
	 * Required params:
	 * swfPath		String		File path to swf that gets placed
	 * 
	 * Optional params:
	 * className	Class		Name of class to trigger when object placed
	 * audioFile	String		Audio file to play when object placed
	 */
	public class PlaceObject extends SpecialAbility
	{				
		override public function activate( node:SpecialAbilityNode ):void
		{	
			var currentState:String = CharUtils.getStateType(entity)
			if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
			{
				super.setActive( true );
				
				// stop player
				MotionUtils.zeroMotion( super.entity );
				CharUtils.stateDrivenOff( super.entity, 0 );
				
				// load asset
				super.loadAsset(_swfPath, loadComplete);
			}
		}	
		
		/**
		 * When asset is loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			if (clip == null)
				return;
			
			// remember clip
			_clip = clip;
			
			// lock player
			CharUtils.lockControls( super.entity, true );
			
			// Play place animation and set listeners
			CharUtils.setAnim( super.entity, Place );
			CharUtils.getTimeline( super.entity ).handleLabel( Animation.LABEL_TRIGGER, placeItem);
			CharUtils.getTimeline( super.entity ).handleLabel( Animation.LABEL_ENDING, onAnimEnd);
		}
		
		/**
		 * Create object entity in scene 
		 */
		protected function placeItem():void
		{	
			// Add the MovieClip to the group
			super.entity.get(Display).container.addChild(_clip);
			
			// Create the new entity and set the display and spatial
			var _objectEntity:Entity = new Entity();
			_objectEntity.add(new Display(_clip, super.entity.get(Display).container));
			
			// Get the Spatial of the hand and use the X,Y to place our object
			var handspatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charspatial:Spatial = super.entity.get(Spatial);
			
			var xPos:Number = charspatial.x - (handspatial.x * charspatial.scale);
			var yPos:Number = charspatial.y + (handspatial.y * charspatial.scale);
			
			// Check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			// Flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				_clip.scaleX = -1;
				xPos = charspatial.x + (handspatial.x * charspatial.scale);
			}
			
			// set position and add to scene
			_objectEntity.add(new Spatial(xPos, yPos));
			super.group.addEntity(_objectEntity);
			
			// play audio
			if(_audioFile)
				AudioUtils.play(super.group, SoundManager.EFFECTS_PATH + _audioFile, 1.5, false);
			
			// if class
			if (_className)
			{
				_clip.gotoAndStop(1);
				var objClass:Object = new _className();
				objClass.init(super.group, _objectEntity);
			}
			else
			{
				trace("PlaceObject: class not found");
			}
			
			additionalSetup(_objectEntity);
		}
		
		/**
		 * additional setup to be overriden by extended classes 
		 */
		protected function additionalSetup(groundEntity:Entity):void
		{
		}
		
		/**
		 * when animation is finished 
		 */
		private function onAnimEnd():void
		{
			super.setActive( false );
			
			// revert to previous animation
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _audioFile:String;
		public var _className:Class;
		
		protected var _clip:MovieClip;
		
		// Imported classes
		private var daisy:Daisy;
		private var firework:Firework;
	}
}