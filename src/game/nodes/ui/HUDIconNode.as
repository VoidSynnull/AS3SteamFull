package game.nodes.ui {

import ash.core.Node;

import engine.components.Motion;
	
public class HUDIconNode extends Node {

	import engine.components.Display;
	import engine.components.Spatial;
	import game.components.ui.HUDIcon;

	public var icon:HUDIcon;
	public var spatial:Spatial;
	public var display:Display;
	public var motion:Motion;

	public function HUDIconNode() {}

}

}
