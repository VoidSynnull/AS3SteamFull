package game.data.animation.entity
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import fl.motion.Motion;
	
	public class PartAnimationData
	{
		private var _motion : Motion;
		private var _kframes : Array;
		public var name : String;
		public var x : int;
		public var y : int;
		public var rotation : int;
		public var xScale : int;
		public var yScale : int;
		public var transformPoint : Point;
		public var dimensions : Rectangle;

		public function PartAnimationData()
		{ }
		
		/**
		 * Call after params have been set
		 */
		public function createOffsets():void
		{
			//_x += _transformPoint.x * ( _dimensions.left - _dimensions.right);
			//_y += _transformPoint.y * ( _dimensions.top - _dimensions.bottom);
		}
		
////////////////////////////// GETTERS/SETTERS ////////////////////////////// 

		public function set motion(motion : Motion):void
		{	
			_motion = motion;
			_kframes = motion.keyframes;
			
			// clean keyframes, basically setting any Nan to zero
			// if a keyframe parameter isn't defined in the xml, it will return NaN
			// this causes glitches when animting, therefore it is take care of here
			// FIXED: jsfl script no longer exports empty values for x & y
			// ADD FIX FOR rotation
		
			for ( var i:uint = 0; i < _kframes.length; i++ )
			{
				if ( isNaN( _kframes[i].rotation ) ) 	
				{ 
					if ( i == 0 )
					{
						_kframes[i].rotation = _motion.source.rotation;
					}
					else 
					{
						_kframes[i].rotation = _kframes[i-1].rotation; 
					}
					
				}
			}
			
		}
		
		public function get motion() : Motion					{ return _motion; }
		public function get kframes() : Array					{ return _kframes; }
	}
}