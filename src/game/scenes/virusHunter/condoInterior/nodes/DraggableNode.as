package game.scenes.virusHunter.condoInterior.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.condoInterior.components.Draggable;

	public class DraggableNode extends Node {

		public var draggable:Draggable;
		public var interaction:Interaction;
		public var spatial:Spatial;

		// Need to the display fo rthe InteractionCreator
		public var display:Display;

	} //

} // End package