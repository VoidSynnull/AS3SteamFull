package game.scenes.deepDive1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.deepDive1.shared.components.SubCamera;
	
	public class SubCameraNode extends Node
	{
		public var subCamera:SubCamera;
		public var display:Display;
		public var spatial:Spatial;
	}
}