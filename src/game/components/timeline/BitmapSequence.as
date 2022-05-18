package game.components.timeline
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import game.data.BitmapFrameData;
	
	/**
	 * Represents a movieclip as a sequence of bitmaps that are displayed
	 * at the appropriate timeline keyframes.
	 */
	public class BitmapSequence extends Component 
	{
		/**
		 * This is a dictionary that matches 'keyframes' of the sequence to BitmapFrameData objects.
		 * Each BitmapFrameData object stores the bitmap, and a rectangle
		 * telling where that bitmap should be positioned within the object.
		 */
		public var frameData:Dictionary = new Dictionary();
		
		/**
		 * This is a list of keyframes occuring in the sequence. e.g. [ 1, 5, 10, 17,... ]
		 */
		public var keyFrames:Vector.<uint> = new Vector.<uint>();
		
		/**
		 * This is a scaling size applied to the bitmap when its drawn.
		 * The bitmap container is subsequently shrunk by a corresponding amount
		 * which gives better smoothing on rotated bitmaps.
		 * 
		 * There is no real reason to have this here except the information
		 * might be useful.
		 */
		public var quality:Number;
		
		public function BitmapSequence(quality:Number = 1)
		{
			this.quality = quality;
		}
		
		public function getFrameData( frame:uint ):BitmapFrameData 
		{
			var fd:BitmapFrameData = frameData[ frame ];
			
			if ( fd == null )
			{
				return frameData[ getKeyFrame( frame ) ];
			}
			
			return fd;
		}
		
		/**
		 * Returns the first keyframe at or before the given frame.
		 */
		public function getKeyFrame( frame:uint ):uint 
		{
			/**
			 * Later we can replace this with binary search.
			 */
			var lastKey:uint = keyFrames[ keyFrames.length-1 ];
			if ( frame >= lastKey ) {
				return lastKey;
			}
			for( var i:int = keyFrames.length-2; i >= 0; i-- ) {
				
				lastKey = keyFrames[i];
				if ( frame >= lastKey ) {
					return lastKey;
				}
			}
			
			// This should never happen.
			return lastKey;
		}
		
		override public function destroy():void
		{
			for(var frame:* in frameData) 
			{
				frameData[frame].destroy();
				delete frameData[frame];
			}
			
			super.destroy();
		}
	}
}