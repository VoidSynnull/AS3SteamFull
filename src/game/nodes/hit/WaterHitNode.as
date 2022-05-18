package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.Water;
	import game.data.scene.hit.HitAudioData;
	
	public class WaterHitNode extends Node
	{
		public var spatial : Spatial;
		public var display : Display;
		public var hit : Water;
		public var hitAudioData:HitAudioData;
		public var optional:Array = [HitAudioData];
	}
}
