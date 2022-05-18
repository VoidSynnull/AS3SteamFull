package game.scenes.shrink.bedroomShrunk02.SeaMonkeySystem
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class SeaMonkey extends Component
	{
		public var tank:Rectangle;
		public var target:Spatial;
		public var speed:Number;
		public var directionTime:Point;
		public var moveTime:Number;
		public var moveToTarget:Boolean;
		public function SeaMonkey(tank:Rectangle = null, target:Spatial = null, speed:Number = 100, directionTime:Point = null)
		{
			this.tank = tank;
			this.target = target;
			this.speed = speed;
			this.directionTime = directionTime;
			if(directionTime == null)
				this.directionTime = new Point(1, 2);
			moveTime = 0;
		}
	}
}