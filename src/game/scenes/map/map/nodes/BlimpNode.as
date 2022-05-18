package game.scenes.map.map.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.TargetEntity;
	import game.scenes.map.map.components.Blimp;
	
	public class BlimpNode extends Node
	{
		public var blimp:Blimp;
		public var spatial:Spatial;
		public var target:TargetEntity;
		public var display:Display;
		public var motion:Motion;
	}
}