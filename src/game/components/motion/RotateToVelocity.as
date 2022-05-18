package game.components.motion
{
	import ash.core.Component;
	
	public class RotateToVelocity extends Component
	{
		public var offset:Number;
		public var limitRotation:Boolean = false;
		public var angle:Number = 0;
		public var range:Number = 0;
		public var rotateEase:Number = 0;
		public var pause:Boolean = false;
		public var mirrorHorizontal:Boolean = false;
		public var originX:Number;
		public var originY:Number;
		
		public function RotateToVelocity(offset:Number = 0, rotateEase:Number = 0)
		{
			this.offset = offset;
			this.rotateEase = rotateEase;
		}
	}
}