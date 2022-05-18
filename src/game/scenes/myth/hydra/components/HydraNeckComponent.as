package game.scenes.myth.hydra.components
{
	import flash.display.MovieClip;
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class HydraNeckComponent extends Component
	{
		public function HydraNeckComponent( _numPoints:Number, _segLength:Number, _angle:Number, _offset:Number, _time:Number )
		{
			numPoints = _numPoints;
			segLength = _segLength;
			angle = _angle;
			offset = _offset;
			time = _time;
			
			var cos:Number = Math.cos( angle );
			var sin:Number = Math.sin( angle );
			
			var number:int;
			var spatial:Spatial;
			
			for( number = 0; number < numPoints; number ++ )
			{
				spatial = new Spatial();
				spatial.x = segLength * ( number + 1 ) * cos;
				spatial.y = segLength * ( number + 1 ) * sin;
				spatial.rotation = angle;
				
				joints.push( spatial );
				
				spatial = new Spatial();
				spatial.x = segLength * ( number + 1 ) * cos;
				spatial.y = segLength * ( number + 1 ) * sin;
				spatial.rotation = angle;
				
				ghostJoints.push( spatial );
				
				spatial = new Spatial();
				spatial.x = segLength * ( number + 1 ) * cos;
				spatial.y = segLength * ( number + 1 ) * sin;
				spatial.rotation = angle;
				
				stiffJoints.push( spatial );
				
				pointTime.push( time * number );
			}
		}
		
		public var numPoints:Number;
		public var segLength:Number;
		public var angle:Number;
		public var offset:Number;
				
		public var joints:Vector.<Spatial> = new Vector.<Spatial>();
		public var ghostJoints:Vector.<Spatial> = new Vector.<Spatial>();
		public var stiffJoints:Vector.<Spatial> = new Vector.<Spatial>();
		public var pointTime:Vector.<Number> = new Vector.<Number>();
		
		public var anchor:MovieClip;
		
		public var time:Number = 0;
	}
}