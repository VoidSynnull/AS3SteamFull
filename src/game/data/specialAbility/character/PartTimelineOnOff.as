// Used by:
// Card 2472 using item ad_pranks_ball (turn on off bouncing ball)
// Card 3053 using facial pastronaut1
// Card 3102 using item pninja1 (numchucks)
// Card 3104 using facial pkight_earth
// Card 3105 using facial pknight_heart
// Card 3136 using facial pgamerdude
// Card 3349 using facial dd_diver

package game.data.specialAbility.character 
{
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.components.timeline.Timeline;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;

	/**
	 * Plays part timeline at labels "on"/"off" to toggle states
	 * This differs from PartTimelineOpenClose in that we do NOT listen for the animation to complete
	 * If you don't need a toggle situation, then use SkinFrameAction in an action chain
	 * When setting the active state. The active state is set immediately.
	 * 
	 * Required params:
	 * partType			String		Name of part type
	 * 
	 * Optional params:
	 * stopWhenJump		Boolean		Stop animation when avatar jumps (default is false)
	 */
	public class PartTimelineOnOff extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			var partEntity:Entity = CharUtils.getPart(super.entity, _partType);
			_timeline = partEntity.get(Timeline);
			
			if(_playUntilMove)
			{
				if(!this.data.isActive)
				{
					this.data.isActive = true;
				}
				else
				{
					return;
				}
			}
			
			if (_timeline)
			{
				if( _isOpen )
				{
					_timeline.gotoAndPlay("off");
					_isOpen = false;
					super.setActive( false );
				}
				else
				{
					_timeline.gotoAndPlay("on");
					_isOpen = true;
					super.setActive( true );
				}
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if (_timeline)
			{
				var motion:Motion = super.entity.get( Motion );
				
				// if stop when jump and active and moving up
				if ((_stopWhenJump) && (super.data.isActive) && (motion.velocity.y != 0) )
				{
					_timeline.gotoAndPlay("off");
					_isOpen = false;
					super.setActive( false );
				}
				if ((_stopWhenMove) && (super.data.isActive) && (motion.velocity.x != 0) )
				{
					_timeline.gotoAndPlay("off");
					_isOpen = false;
					super.setActive( false );
				}
			}
		}
		
		public var required:Array = ["partType"];
		
		public var _partType:String;
		public var _stopWhenJump:Boolean = false;
		public var _stopWhenMove:Boolean = false;
		public var _playUntilMove:Boolean = false;
		private var _timeline:Timeline;
		private var _isOpen:Boolean = false;
		private var _action:Class;
		private var _label:String;
	}
}