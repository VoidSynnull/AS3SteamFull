package game.ui.photo
{
	import flash.display.DisplayObjectContainer;

	public class PartPoseData
	{
		public var x:Number;
		public var y:Number;
		public var rotation:Number;
		public var limb:Boolean;
		
		public function PartPoseData(display:DisplayObjectContainer = null, limb:Boolean = false)
		{
			if(display != null)
			{
				x = display.x;
				y = display.y;
				rotation = display.rotation;
			}
			this.limb = limb;
		}
	}
}