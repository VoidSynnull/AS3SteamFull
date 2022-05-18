package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.Bounce;
	import game.data.scene.hit.HitAudioData;
	
	public class BounceBitmapHitNode extends Node
	{
		public var hit:Bounce;
		public var bitmapHit:BitmapHit;
		public var hitAudioData:HitAudioData;
		public var id:Id;
		public var optional:Array = [Id,HitAudioData];
	}
}