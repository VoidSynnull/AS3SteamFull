// Status: retired
// Usage (1) ads
// Used by avatar item limited_goldfish_flashlight

package game.data.specialAbility.custom
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Salute;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.TimelineUtils;
	
	public class Flashlight extends SpecialAbility
	{
		private var _timeline:Timeline;
		private var _counter:int;
		
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			var itemPart:Entity = CharUtils.getPart(node.entity, CharUtils.ITEM);
			var entity:Entity = TimelineUtils.convertClip(itemPart.get(Display).displayObject.content, super.group);
			_timeline = entity.get(Timeline);
			_timeline.gotoAndStop("start");
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				CharUtils.setAnim(node.entity, Salute);
				CharUtils.getTimeline(node.entity).handleLabel("raised", turnOn);
				super.setActive( true );
			}
		}
		
		private function turnOn():void
		{
			// Check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			// Flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
				_timeline.gotoAndPlay("left");
			else
				_timeline.gotoAndPlay("right");
			_counter = 0;
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if ( super.data.isActive )
			{
				_counter++;
				if (_counter >= 30)
					deactivate(node);
			}
		}

		override public function deactivate( node:SpecialAbilityNode ):void
		{
			_timeline.gotoAndStop("start");
			super.setActive( false );
		}
	}
}
