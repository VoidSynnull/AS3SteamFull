package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Hazard;
	import game.components.motion.Edge;
	import game.data.scene.hit.HitAudioData;
	
	public class HazardHitNode extends Node
	{
		public var display:Display;
		public var hit:Hazard;
		public var spatial:Spatial;
		public var hitAudioData:HitAudioData;
		public var motion:Motion;
		public var edge:Edge;
		public var optional:Array = [HitAudioData, Motion, Edge];
	}
}
