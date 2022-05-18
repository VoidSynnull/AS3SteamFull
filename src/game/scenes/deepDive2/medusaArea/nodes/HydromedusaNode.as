package game.scenes.deepDive2.medusaArea.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	
	import game.scenes.deepDive2.medusaArea.components.Hydromedusa;
	
	public class HydromedusaNode extends Node
	{
		public var hydromedusa:Hydromedusa;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
		public var sleep:Sleep;
	}
}