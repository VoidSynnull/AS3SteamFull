// Used by:
// Card 2901 with overpants part limited_bh6_baymax

package game.data.specialAbility.character
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.timeline.Timeline;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	
	/**
	 * Add legs behavior to overpants part
	 */
	public class Legs extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			var partEntity:Entity = CharUtils.getPart(super.entity, _part);
			_timeline = partEntity.get(Timeline);
			_timeline.gotoAndStop(_state);
			// if motion is not found on entity, then deactivate
			if (entity.get(Motion) == null)
			{
				super.deactivate(node);
				return;
			}
			_timeline.labelReached.add(checkLabel);
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			this.setActive(true);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			var motion:Motion = entity.get(Motion);
			if (motion != null)
			{
				var control:CharacterMotionControl = entity.get(CharacterMotionControl);
				var velocity:Point = motion.velocity;
				var speedX:Number = Math.abs(velocity.x);
				var speedY:Number = velocity.y;
				if (speedY != 0)
				{
					if (speedY > 0)
					{
						if (_state != "jump")
						{
							_state = "jump";
							_timeline.gotoAndPlay(_state);
						}
					}
				}
				else if (speedX >= control.runSpeed)
				{
					// 440
					if (_state != "run")
					{
						_state = "run";
						_timeline.gotoAndPlay(_state);
					}
				}
				else if (speedX >= control.walkSpeed)
				{
					// 10
					if (_state != "walk")
					{
						_state = "walk";
						_timeline.gotoAndPlay(_state);
					}
				}
				else
				{
					if (_state != "stand")
					{
						_state = "stand";
						_timeline.gotoAndStop(_state);
					}
				}
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			super.deactivate(node);
		}
		
		private function checkLabel(label:String):void
		{
			switch(label)
			{
				case "walk_end":
					_timeline.gotoAndPlay("walk_loop");
					break;
				case "run_end":
					_timeline.gotoAndPlay("run_loop");
					break;
				case "land":
					_timeline.gotoAndStop("stand");
					break;
			}
		}
		
		public var _part:String = "overpants"; 
		private var _timeline:Timeline;
		private var _state:String = "stand";
	}
}