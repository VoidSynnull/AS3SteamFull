package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.Platform;
	import game.data.scene.hit.HitAudioData;
	
	public class PlatformBitmapHitNode extends Node
	{
		public var hit:Platform;
		public var bitmapHit:BitmapHit;
		public var hitAudioData:HitAudioData;
		public var id:Id
		public var optional:Array = [HitAudioData,Id];
	}
}
