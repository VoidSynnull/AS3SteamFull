package game.scenes.survival2.beaverDen.components
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class DamControlComponent extends Component
	{
		public var activeLeaks:int = 0;
		public var active:Boolean = false;
		public var victory:Boolean = false;
		public var waterSpatial:Spatial;
		public var timer:Number;
	}
}