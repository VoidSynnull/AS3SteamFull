package game.data.animation
{
	
	// Contains the data for an animations timeline.
	public class TimelineData
	{
		public var duration : int; 
		private var _frames : Vector.<FrameData>;	// Array of FrameData, contains the data for a single frame including FrameEvents
		
		public function TimelineData()
		{	
			_frames = new Vector.<FrameData>;
		}
		
		/**
		 * Returns the frame index of the provided label, if label is not found returns -1; 
		 * @param label
		 * @return 
		 */
		public function getLabelIndex(label:String):Number
		{
			var frame:FrameData;
			
			for (var n:Number = 0; n < _frames.length; n++)
			{
				frame = _frames[n];
				
				if (frame.label == label)
				{
					return(frame.index);
				}
			}
			
			return(-1);
		}

		public function setFrame(index:Number, frame:FrameData):void { _frames[index] = frame; }
		public function getFrame(index:Number):FrameData { return _frames[index]; }
		public function set frames(frames:Vector.<FrameData>):void { _frames = frames; }
		
		public function getPreviousLabel(currentFrame:int):FrameData
		{
			if(currentFrame < 0) return null;
			if(currentFrame > this._frames.length - 1) return null;
			
			for(var index:int = currentFrame; index > -1; --index)
			{
				if(this._frames[index].label)
				{
					return this._frames[index];
				}
			}
			
			return null;
		}
		
		public function getNextLabel(currentFrame:int):FrameData
		{
			if(currentFrame < 0) return null;
			if(currentFrame > this._frames.length - 1) return null;
			
			for(var index:int = currentFrame; index < this._frames.length; ++index)
			{
				if(this._frames[index].label)
				{
					return this._frames[index];
				}
			}
			
			return null;
		}
	}	
}
