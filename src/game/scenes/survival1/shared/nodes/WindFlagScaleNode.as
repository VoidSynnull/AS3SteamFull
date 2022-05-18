package game.scenes.survival1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.survival1.shared.components.WindFlag;
	import game.scenes.survival1.shared.components.WindFlagScale;
	
	public class WindFlagScaleNode extends Node
	{
		public var windFlagScale:WindFlagScale;
		public var windFlag:WindFlag;
		public var spatial:Spatial;
	}
}