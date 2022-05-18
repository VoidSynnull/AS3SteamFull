package game.components.entity
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import engine.components.Spatial;
	
	public class FollowClipInTimeline extends Component
	{
		public function FollowClipInTimeline(clip:DisplayObject = null, offSet:Point = null, parent:Spatial = null, followRotation:Boolean = false, rotationOffset:Number = 0)
		{
			this.clip = clip;
			this.offSet = offSet;
			this.parent = parent;
			this.followRotation = followRotation;
			this.rotationOffset = rotationOffset;
			if(this.offSet == null)
				this.offSet = new Point();
			this.parent = parent;
		}
		
		public function offSetClipByParents():void // this helps by taking care of all parenting offsets
		{
			var parent:DisplayObjectContainer = clip.parent;

			while(parent != null)
			{
				if(parent.name == "cameraContainer" || parent["bitmapHits"] != null)
					break;
				offSet.x += parent.x;
				offSet.y += parent.y;
				parent = parent.parent;// find the next level of parenting
			}
		}
		public var clip:DisplayObject;
		public var offSet:Point; // extra offset to make things look more natural
		public var followRotation:Boolean;
		public var rotationOffset:Number;
		public var parent:Spatial;
	}
}