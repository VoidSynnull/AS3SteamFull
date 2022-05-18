package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Platform;
	import game.data.scene.hit.HitAudioData;
	
	public class PlatformHitNode extends Node
	{
		public var spatial : Spatial;
		public var display : Display;
		public var hit : Platform;
		public var hitAudioData:HitAudioData;
		public var motion:Motion;
		public var id:Id;
		public var optional:Array = [HitAudioData,Motion,Id];
	}
}
