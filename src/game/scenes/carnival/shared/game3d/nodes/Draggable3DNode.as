package game.scenes.carnival.shared.game3d.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;

	import game.scenes.carnival.shared.game3d.components.Spatial3D;
	import game.scenes.carnival.shared.game3d.components.Draggable3D;

	public class Draggable3DNode extends Node {

		public var display:Display;		// Need this for releaseOutside, i think.
		public var interaction:Interaction;

		public var draggable:Draggable3D;
		public var spatial:Spatial3D;

	} // End Draggable3DNode

} // End package