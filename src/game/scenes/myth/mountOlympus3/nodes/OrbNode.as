package game.scenes.myth.mountOlympus3.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.scenes.myth.mountOlympus3.components.Orb;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	
	public class OrbNode extends Node
	{
		public var audio:Audio;
		public var orb:Orb;
		public var tween:Tween;
		public var electrify:ElectrifyComponent;
		public var display:Display;
		public var spatial:Spatial;
		public var sleep:Sleep;
		public var motion:Motion;
		public var hazard:Hazard;
	}
}