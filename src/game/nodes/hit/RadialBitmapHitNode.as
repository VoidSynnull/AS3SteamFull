package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Id;
	
	import game.components.hit.BitmapHit;
	import game.components.hit.Radial;
	import game.data.scene.hit.HitAudioData;
	
	public class RadialBitmapHitNode extends Node
	{
		public var hit:Radial;
		public var bitmapHit:BitmapHit;
		public var hitAudioData:HitAudioData;
		public var id:Id;
		public var optional:Array = [HitAudioData,Id];
	}
}