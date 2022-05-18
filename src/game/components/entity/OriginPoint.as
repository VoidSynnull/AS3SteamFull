package game.components.entity
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class OriginPoint extends Component
	{
		public var x:Number;
		public var y:Number;
		public var rotation:Number;
		
		public function OriginPoint(x:Number = 0, y:Number = 0, rotation:Number = 0)
		{
			this.x 			= x;
			this.y 			= y;
			this.rotation 	= rotation;
		}
		public function applyToSpatial(spatial:Spatial, applyRotation:Boolean = false):void
		{
			spatial.x = x;
			spatial.y = y;
			if(applyRotation){
				spatial.rotation = rotation;
			}
		}
	}
}