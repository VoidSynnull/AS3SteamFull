package game.scenes.virusHunter.lungs.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.lungs.components.BossBody;
	import game.scenes.virusHunter.lungs.components.BossState;
	
	public class BossBodyNode extends Node
	{
		public var body:BossBody;
		public var state:BossState;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}