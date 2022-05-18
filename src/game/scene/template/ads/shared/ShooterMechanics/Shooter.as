package game.scene.template.ads.shared.ShooterMechanics
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Shooter extends Component
	{
		public var speed:Number = 1800;//bullet speed
		public var axis:String = "x";//x, y, z(both)
		public var offset:Point = new Point();
		public var fireRate:Number = .5;
		public var bulletRotation:Number = 0;
		public var pool:Array = [];
		public var targetPrefix:String;
		
		public var bulletAsset:*;
		public var bulletContainer:DisplayObjectContainer;
		public function Shooter(bulletAsset:*, bulletContainer:DisplayObjectContainer)
		{
			this.bulletAsset = bulletAsset;
			this.bulletContainer = bulletContainer;
		}
	}
}