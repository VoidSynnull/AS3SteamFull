package game.scenes.time.china.components
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	public class FallingBrick extends Component
	{
		public var scene:Scene;
		public var hit:Entity;
		public var hitMotion:Motion;
		public var hitSpatial:Spatial;
		
		public var state:String;
		public var velocity:Number;
		public var spinSpeed:Point; // x = min spin speed, y = max spin speed
		public var startPos:Point;
		public var range:Rectangle;
		public var waitTime:Number;
	}
}