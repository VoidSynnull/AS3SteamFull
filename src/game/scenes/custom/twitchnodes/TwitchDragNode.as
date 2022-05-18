package game.scenes.custom.twitchnodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	
	import game.scenes.custom.twitchcomponents.DraggableComponent;
	
	public class TwitchDragNode extends Node {
		
		public var draggable:DraggableComponent;
		public var interaction:Interaction;
		public var spatial:Spatial;
		
		// Need to the display for the InteractionCreator
		public var display:Display;
		
	}
	
}