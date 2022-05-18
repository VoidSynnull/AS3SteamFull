package game.scenes.survival2.trees.SplatBug
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class SplatBug extends Component
	{
		public var asset:MovieClip;
		public var origin:Point;
		public var wanderRadius:Number;
		public var wanderSpeed:Number;
		public function SplatBug(asset:MovieClip, wanderRadius:Number = 100, wanderSpeed:Number = 8)
		{
			this.asset = asset;
			this.wanderRadius = wanderRadius;
			this.wanderSpeed = wanderSpeed;
			origin = new Point(asset.x, asset.y);
		}
	}
}