package game.scenes.carrot.robot
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	public class RotatingPlatform extends Component
	{
		public var pivotPoint:Point;
		public var spatial:Spatial;
		public var display:Entity;
		public var motion:Motion;
		
		public function RotatingPlatform( pivotX:Number, pivotY:Number )
		{
			pivotPoint = new Point( pivotX, pivotY );
		}
	}
}