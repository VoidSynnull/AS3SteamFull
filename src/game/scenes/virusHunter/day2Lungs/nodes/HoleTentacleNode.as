package game.scenes.virusHunter.day2Lungs.nodes 
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.scenes.virusHunter.day2Lungs.components.HoleTentacle;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Tentacle;

	public class HoleTentacleNode extends Node
	{
		public var hole:HoleTentacle;
		public var tentacle:Tentacle;
		public var tween:Tween;
		public var spatial:Spatial;
		public var target:DamageTarget;
		public var audio:Audio;
	}
}