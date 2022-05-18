package game.scenes.lands.shared.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;

	import game.scenes.lands.shared.components.SimpleTarget;

	public class SimpleTargetNode extends Node {

		public var spatial:Spatial;
		public var display:Display;

		public var target:SimpleTarget;

	} // class
	
} // package