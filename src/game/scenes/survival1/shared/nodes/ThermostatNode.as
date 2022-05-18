package game.scenes.survival1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.WaterCollider;
	import game.scenes.survival1.shared.components.ThermostatGaugeComponent;
	
	public class ThermostatNode extends Node
	{
		public var audio:Audio;
		public var collider:WaterCollider;
		public var gauge:ThermostatGaugeComponent;
		public var motion:Motion;
		public var spatial:Spatial;
	}
}