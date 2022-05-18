package game.scenes.carnival.shared.ferrisWheel.nodes {
	
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisArm;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisAxle;
	
	
	public class FerrisArmNode extends Node {
		
		public var arm:FerrisArm;

		public var spatial:Spatial;
		public var axle:FerrisAxle;

	} // End FerrisArmNode

} // End package