package game.scenes.virusHunter.day2Heart.nodes 
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.day2Heart.components.WormTentacle;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class WormTentacleNode extends Node
	{
		public var tentacle:WormTentacle;
		public var spatial:Spatial;
		public var target:DamageTarget;
		public var sleep:Sleep;
		public var audio:Audio;
	}
}