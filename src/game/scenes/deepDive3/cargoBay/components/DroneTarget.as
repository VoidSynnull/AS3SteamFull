package game.scenes.deepDive3.cargoBay.components 
{
	import flash.geom.Point;
	
	import ash.core.Component;
		
	public class DroneTarget extends Component
	{
		public var active:Boolean = false;
		public var pos:Point;
		public var angle:Number;
		
		public function DroneTarget(a:Number)
		{
			angle = a;
		}
	}
}