package game.scenes.carrot.smelter.components
{
	import ash.core.Component;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	public class Smasher extends Component
	{
		public var state:String;
		public var innerSmasher:Boolean = true;
		
		public var wallSpatial:Spatial;
		public var wallMotion:Motion;
		public var capSpatial:Spatial;
		public var capMotion:Motion;
		
		public const START_UP:String 	= "start_up";
		public const PAUSE_UP:String	= "pause_up";
		public const START_DOWN:String	= "start_down";
		public const PAUSE_DOWN:String	= "pause_down";
	}
}