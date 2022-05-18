package game.scenes.lands.shared.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.ui.ToolTip;
	import game.scenes.lands.shared.components.SharedToolTip;

	public class SharedToolTipNode extends Node {

		public var shared:SharedToolTip;
		public var toolTip:ToolTip;

		public var display:Display;
		public var spatial:Spatial;

	} // class
	
} // package