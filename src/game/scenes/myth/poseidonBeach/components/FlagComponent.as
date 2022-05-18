package game.scenes.myth.poseidonBeach.components
{
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class FlagComponent extends Component
	{		
		public var points:Vector.<Spatial> = new Vector.<Spatial>;
		public var startY:Vector.<Number> = new Vector.<Number>;
		public var timers:Vector.<Number> = new Vector.<Number>;
		public var speed:Number = .05;
	}
}