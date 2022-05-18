package game.scenes.carnival.shared.ferrisWheel.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisAxle;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisSwing;

	public class FerrisSwingNode extends Node {
		
		public var spatial:Spatial;
		public var swing:FerrisSwing;

		public var motion:Motion;

		public var display:Display;

		public var axle:FerrisAxle;

	} // End FerrisSwingNode
	
} // End package