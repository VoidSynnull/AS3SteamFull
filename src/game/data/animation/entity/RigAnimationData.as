package game.data.animation.entity
{
	import flash.utils.Dictionary;
	
	import game.data.animation.FrameData;
	
	// RigAnimationData
	// Contains PartAnimationData for all rigs parts of an animation.
	
	public class RigAnimationData
	{
		public var name:String;
		public var duration:int; 
		public var noEnd:Boolean = false;	// flag determining if animation should remain on last frame.
		public var frames:Vector.<FrameData>;
		private var _parts:Dictionary; 	// contains PartAnimationData instances
		

		public function RigAnimationData()
		{	
			_parts = new Dictionary(true);
			frames = new Vector.<FrameData>;
		}
				
		public function addPart( part:PartAnimationData ):void
		{
			_parts[ part.name ] = part;
		}

		public function getPart( partName :String ) : PartAnimationData
		{	
			return _parts[ partName ];
		}
		
		public function getLabelIndex( label:String ):int
		{
			var frameData:FrameData;
			for (var i:int = 0; i < frames.length; i++) 
			{
				frameData = frames[i];
				if( frameData.label == label )
				{
					return frameData.index;
				}
			}
			return -1;
		}
		
	
////////////////////////////// GETTERS/SETTERS ////////////////////////////// 
		
		public function get parts() : Dictionary
		{	return _parts; }
	}	
}
