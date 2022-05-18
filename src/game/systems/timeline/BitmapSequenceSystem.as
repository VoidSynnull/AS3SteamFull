package game.systems.timeline
{
	import flash.display.Bitmap;
	
	import game.data.BitmapFrameData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.timeline.BitmapSequenceNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class BitmapSequenceSystem extends GameSystem
	{
		public function BitmapSequenceSystem() 
		{
			super( BitmapSequenceNode, updateNode, nodeAdded);
			super._defaultPriority = SystemPriorities.animate;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}

		public function updateNode(node:BitmapSequenceNode, time:Number):void
		{
			var frame:int = node.timeline.currentIndex + 1;
			
			if(node.bitmapTimeline.frame != frame)
			{
				node.bitmapTimeline.frame = frame;
				
				var frameData:BitmapFrameData 	= node.sequence.getFrameData(frame);
				var bitmap:Bitmap 				= node.bitmapTimeline.bitmap;
				
				bitmap.bitmapData 	= frameData.data;
				bitmap.x 			= frameData.x;
				bitmap.y 			= frameData.y;
			}
		}
		
		public function nodeAdded(node:BitmapSequenceNode):void
		{
			var frame:int 				= node.timeline.currentIndex + 1;
			node.bitmapTimeline.frame 	= frame;

			var frameData:BitmapFrameData 	= node.sequence.getFrameData(frame);
			var bitmap:Bitmap 				= node.bitmapTimeline.bitmap;

			bitmap.bitmapData 	= frameData.data;
			bitmap.x 			= frameData.x;
			bitmap.y 			= frameData.y;

		}
	}
}