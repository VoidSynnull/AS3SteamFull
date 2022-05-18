package game.scenes.con3.shared.rayRender
{
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.scenes.con3.shared.Ray;
	
	public class RayRenderNode extends Node
	{
		public var render:RayRender;
		public var ray:Ray;
		public var display:Display;
	}
}