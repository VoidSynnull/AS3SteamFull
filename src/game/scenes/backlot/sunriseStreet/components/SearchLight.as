package game.scenes.backlot.sunriseStreet.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class SearchLight extends Component
	{
		public var speed:Number;
		public var limits:Point;
		public var rotation:Number;
		public var rotateClockWise:Boolean;
		public function SearchLight(speed:Number, limits:Point, startMin:Boolean, rotateClockWise:Boolean)
		{
			this.speed = speed;
			this.limits = limits;
			this.rotateClockWise = rotateClockWise;
			if(startMin)
				rotation = limits.x;
			else
				rotation = limits.y;
		}
	}
}