package game.scenes.virusHunter.lungs.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.lungs.components.Boss;
	import game.scenes.virusHunter.lungs.components.BossState;
	
	public class BossNode extends Node
	{
		public var boss:Boss;
		public var state:BossState;
		public var spatial:Spatial;
	}
}