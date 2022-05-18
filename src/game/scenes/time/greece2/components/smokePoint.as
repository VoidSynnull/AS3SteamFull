package game.scenes.time.greece2.components
{
	import flash.geom.Point;
	
	// simple extention of point class for smoke wisp system
	public class smokePoint extends Point
	{
		public var velX:Number = 0;
		public var velY:Number = 0;
		
		public function smokePoint(x:Number=0, y:Number=0, velX:Number = 0, velY:Number = 0)
		{
			this.velX = velX;
			this.velY = velY;
			super(x, y);
		}
	}
}