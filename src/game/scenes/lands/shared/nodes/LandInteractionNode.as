package game.scenes.lands.shared.nodes {

	import ash.core.Node;

	import game.scenes.lands.shared.components.FocusTileComponent;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.components.LandInteraction;

	public class LandInteractionNode extends Node {

		/**
		 * for now, this is mainly a marker class.
		 */
		public var interaction:LandInteraction;

		/**
		 * the focused tile gives which tile is under the mouse, and hence which tile is being
		 * clicked, or should be used as a rollOver.
		 */
		public var tileFocus:FocusTileComponent;

		public var editContext:LandEditContext;

	} // class
	
} // package