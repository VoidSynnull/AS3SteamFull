package game.scenes.myth.poseidonThrone.components
{
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class PoseidonBeardComponent extends Component
	{		
		public var radius:int = 16;
		public var magnitute:int = 30;
		public var thickness:int = 16;
		
		public var speed:Number = .05;
		
		public var timers:Vector.<Number> = new Vector.<Number>;
		public var mustachio:Vector.<Vector.<Spatial>> = new Vector.<Vector.<Spatial>>;
	}
}