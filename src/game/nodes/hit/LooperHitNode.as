package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.motion.Looper;
	import game.data.scene.hit.HitAudioData;
	import game.data.scene.hit.HitData;
	
	public class LooperHitNode extends Node
	{
		public var looperHit:Looper;
		public var sleep:Sleep;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
		
		public var audio:Audio;
		public var edge:Edge;
		public var hitAudioData:HitAudioData;
		public var hitData:HitData;
		public var id:Id;
		public var optional:Array = [ Audio, Edge, HitAudioData, HitData, Id ];
	}
}