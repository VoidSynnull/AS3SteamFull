package game.scenes.lands.shared.popups.worldManagementPopup.nodes{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.popups.worldManagementPopup.components.World;
	
	public class WorldNode extends Node
	{
		public var world:World;
		public var display:Display;
		public var spatial:Spatial;
	}
}