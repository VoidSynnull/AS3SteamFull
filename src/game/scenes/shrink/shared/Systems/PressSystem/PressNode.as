package game.scenes.shrink.shared.Systems.PressSystem
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.ValidHit;
	
	public class PressNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var press:Press;
		
		public var validHits:ValidHit;
		
		public var optional:Array = [ValidHit];
	}
}