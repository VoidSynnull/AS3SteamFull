package game.scenes.lands.shared.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.components.LandMeteor;

	public class LandMeteorNode extends Node {
		
		public var spatial:Spatial;
		public var motion:Motion;

		public var meteor:LandMeteor;
		public var display:Display;
		
	} // class
	
} // package