package game.scenes.survival1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.shrink.mainStreet.StreamerSystem.Streamer;
	import game.scenes.survival1.shared.components.WindFlag;
	
	public class WindFlagNode extends Node
	{
		public var flag:Streamer;
		public var spatial:Spatial;
		public var windFlag:WindFlag;
	}
}