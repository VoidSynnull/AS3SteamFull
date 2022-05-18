package game.scenes.mocktropica.university
{
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	
	public class ClockTimeSystem extends System
	{
		public var _hourHand:Entity
		public var _minuteHand:Entity
		public var date:Date;
		
		
		public function init (  __hourhand:Entity, __minuteHand:Entity):void{
			_hourHand = __hourhand;
			_minuteHand = __minuteHand;
		}
		
		override public function update( time : Number ) : void
		{
			
			date = new Date();
			var mins:uint = date.getMinutes();
			var hours:uint = date.getHours();
			_hourHand.get(Spatial).rotation = (360 * (hours / 12)) + (30 * (mins / 60));
			_minuteHand.get(Spatial).rotation = 360 * (mins / 60);
			
		}
	}
}