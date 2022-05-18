package game.systems.dragAndDrop
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Drag extends Component
	{
		public var origin:Point;
		public var rate:Number;
		public var enabled:Boolean = true;
		public var id:String;
		public var asset:DisplayObjectContainer;
		
		public function Drag(asset:DisplayObjectContainer, id:String = null,origin:Point = null, rate:Number = 1)
		{
			this.asset = asset;
			this.id = id;
			this.origin = origin;
			this.rate = rate;
		}
	}
}