package game.scenes.shrink.shared.Systems.CarControlSystem
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.shrink.shared.Systems.CarSystem.Car;
	
	public class CarControlNode extends Node
	{
		public var controls:CarControl;
		public var car:Car;
		public var motion:Motion;
		public var spatial:Spatial;
		public var audio:Audio;
	}
}