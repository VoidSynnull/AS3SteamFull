package game.scenes.virusHunter.foreArm.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.foreArm.components.Cut;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	
	public class CutNode extends Node
	{
		public var cut:Cut;
		public var id:Id;
		public var display:Display;
		public var spatial:Spatial;
		public var damageTarget:DamageTarget;
	}
}