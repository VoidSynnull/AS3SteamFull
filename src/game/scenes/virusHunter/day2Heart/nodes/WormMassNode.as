package game.scenes.virusHunter.day2Heart.nodes 
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.day2Heart.components.WormMass;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class WormMassNode extends Node
	{
		public var mass:WormMass;
		public var spatial:Spatial;
		public var target:DamageTarget;
		public var sleep:Sleep;
		public var tween:Tween;
		public var id:Id;
		public var timeline:Timeline;
		public var audio:Audio;
	}
}