package game.scenes.lands.shared.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.scenes.lands.shared.components.ThrowHammer;
	
	public class ThrowHammerNode extends Node {
		
		public var spatial:Spatial;
		public var display:Display;
		
		public var target:TargetSpatial;
		
		public var hammer:ThrowHammer;
		public var motion:Motion;
		
	} // class
	
} // package