package game.nodes.hit
{
	import ash.core.Node;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.Hazard;
	import game.data.scene.hit.HitAudioData;
	
	public class HazardBitmapHitNode extends Node
	{
		public var hit:Hazard;
		public var bitmapHit:BitmapHit;
		public var hitAudioData:HitAudioData;
		public var optional:Array = [HitAudioData];
	}
}