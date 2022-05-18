package game.scenes.carnival.shared.ferrisWheel.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisAxle;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisWheel;

	public class FerrisWheelNode extends Node {

		public var spatial:Spatial;
		//public var display:Display;

		public var motion:Motion;

		public var ferrisWheel:FerrisWheel;
		public var axle:FerrisAxle;

	} // End FerrisWheelNode

} // End package