// Used by:
// Card 2716 using item llimited_avengers_repuslor
// Card 3010 using item pRobinhood1
// Card 3014 using item probot
// Card 3039 and 3040 using item pRevolver
// Card 3042 using item probot2
// Card 3043 using item probot3
// Card 3045 using item probot5
// Card 3058 using item pRobot1b
// Card 3066 using item pRobinhood1 (shoot arrow)
// Card 3225 using item sponsorshrinkray (scales down NPCs 50 percent)

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Sword;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	
	/**
	 * Shoot gun using item part timeline
	 * 
	 * Optional params:
	 * animationClass		Class		avatar animation class (default is Sword)
	 * triggerFrame			String		animation trigger frame (default is "fire")
	 * toggleClipName		String		name of embedded movie clip in item part to toggle on/off
	 */
	public class TimelineGun extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			// get item part entity
			partEntity = CharUtils.getPart(super.entity, "item");
			
			// turn off toggle clip if exists
			if (_toggleClipName)
				toggleClip(false);
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{	
			if ( !super.data.isActive )
			{
				var currentState:String = CharUtils.getStateType(entity)
				if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
				{
					setActive( true );
					
					// lock controls
					CharUtils.lockControls( super.entity, true, false );
					
					// set animation and listeners
					CharUtils.setAnim( super.entity, _animationClass );
					CharUtils.getTimeline( super.entity ).handleLabel( Animation.LABEL_ENDING, completed );
					CharUtils.getTimeline( super.entity ).handleLabel(_triggerFrame, fireGun );
				}
			}
		}
		
		/**
		 * Fire gun 
		 */
		private function fireGun():void
		{
			// play item part timeline
			var timeline:Timeline = partEntity.get(Timeline);
			timeline.play();
			
			// if toggle clip exists, then turn on
			if (_toggleClipName)
				toggleClip(true);
			
			// if instance flip exists, flip that part the correct direction
			if(_instanceFlip)
			{
				var spatial:Spatial = entity.get(Spatial);
				var clip:MovieClip = partEntity.get(Display).displayObject as MovieClip;
				var instanceArray:Array = _instanceFlip.split(".");
 				for(var i:uint = 0; i < instanceArray.length; i++)
				{
					var child:String = instanceArray[i];
					clip = clip.getChildByName(child) as MovieClip;
					
					if(!clip)
					{
						
					}
				}
				
				if(clip)
				{
					if(spatial.scaleX < 0)
					{
						// facing Right
						clip.gotoAndStop(2);
					}
					else
					{
						// facing left
						clip.gotoAndStop(1);
					}
				}
			}
			
			// trigger any now actions (add delay to action in xml if you want delay)
			actionCall(SpecialAbilityData.NOW_ACTIONS_ID);
		}
		
		/**
		 * When animation done 
		 */
		private function completed():void
		{
			super.setActive( false );
			
			// restore avatar
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
			
			// if toggle clip exists, then turn off
			if (_toggleClipName)
				toggleClip(false);
		}
		
		/**
		 * Toggle clip on/off 
		 * @param state
		 */
		private function toggleClip(state:Boolean):void
		{
			var clip:MovieClip = MovieClip(partEntity.get(Display).displayObject);
			
			// if clip and toggle clip exists then turn on/off
			if ((clip) && (clip[_toggleClipName]))
				clip[_toggleClipName].visible = state;
		}
		
		public var _animationClass:Class = Sword;
		public var _triggerFrame:String = "fire";
		public var _toggleClipName:String;
		public var _instanceFlip:String;
		
		private var partEntity:Entity;
	}
}