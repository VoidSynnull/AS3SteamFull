package game.scenes.virusHunter.lungs.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.lungs.components.BossClaw;
	import game.scenes.virusHunter.lungs.components.BossState;
	
	public class BossClawNode extends Node
	{
		public var claw:BossClaw;
		public var state:BossState;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}