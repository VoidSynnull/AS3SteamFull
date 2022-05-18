package game.components.motion
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class PulleyObject extends Component
	{
		public function PulleyObject(oppositeSide:Entity, maxY:Number)
		{
			this.opposite = oppositeSide;
			this.maxY = maxY;
			startMoving = new Signal(Entity);
			stopMoving = new Signal(Entity);
		}
		
		public var opposite:Entity; // Must also be a pulleyObject
		public var maxY:Number;
		public var currentCollisions:Vector.<String> = new Vector.<String>;
		public var wheel:DisplayObjectContainer;
		public var wheelSpeedMultiplier:Number = .25;
		public var moving:Boolean;
		public var startMoving:Signal;
		public var stopMoving:Signal;
	}
}