package game.scenes.survival1.cave.turnToTarget
{
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class TurnToTarget extends Component
	{
		public var target:Spatial;
		
		public var offsetX:Number;
		public var offsetY:Number;
		
		public var axis:String;
		
		public var reverseX:Boolean;
		public var reverseY:Boolean;
		
		public function TurnToTarget(target:Spatial, axis:String = null, offsetX:Number = 0, offsetY:Number = 0, reverseX:Boolean = false, reverseY:Boolean = false)
		{
			this.target 	= target;
			this.axis 		= axis;
			this.offsetX	= offsetX;
			this.offsetY	= offsetY;
			this.reverseX 	= reverseX;
			this.reverseY 	= reverseY;
		}
	}
}