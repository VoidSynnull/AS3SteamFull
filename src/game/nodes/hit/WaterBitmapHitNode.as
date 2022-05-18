package game.nodes.hit
{
	import ash.core.Node;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.Water;
	import game.data.scene.hit.HitAudioData;
	
	public class WaterBitmapHitNode extends Node
	{
		public var hit:Water;
		public var bitmapHit:BitmapHit;
		public var hitAudioData:HitAudioData;
		public var optional:Array = [HitAudioData];
	}
}
