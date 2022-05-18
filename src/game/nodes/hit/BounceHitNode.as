package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.Bounce;
	import game.data.scene.hit.HitAudioData;
	
	public class BounceHitNode extends Node
	{
		public var spatial : Spatial;
		public var display : Display;
		public var hit : Bounce;
		public var hitAudioData:HitAudioData;
		public var id:Id;
		public var optional:Array = [Id,HitAudioData];
	}
}
