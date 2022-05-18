package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.PlatformRebound;
	import game.data.scene.hit.HitAudioData;
	
	public class PlatformReboundHitNode extends Node
	{
		public var spatial:Spatial;
		public var display:Display;
		public var hit:PlatformRebound;
		public var hitAudioData:HitAudioData;
		public var motion:Motion;
		public var id:Id;
		public var optional:Array = [HitAudioData,Motion,Id];
	}
}