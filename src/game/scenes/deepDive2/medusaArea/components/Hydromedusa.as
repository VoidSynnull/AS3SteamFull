package game.scenes.deepDive2.medusaArea.components 
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class Hydromedusa extends Component
	{
		public var target:Spatial;
		public var foundSwitch:Boolean = false;
		public var active:Boolean = false;
		public var stung:Boolean = false;
		public var statementWait:Boolean = false;
		public var pos:Point;
		
		public function Hydromedusa(_x:Number, _y:Number)
		{
			pos = new Point(_x, _y);
		}
	}
}