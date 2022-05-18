package game.scenes.lands.shared.nodes {
	
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.components.LandWeatherCollider;
	import game.scenes.lands.shared.components.Life;
	
	public class WeatherColliderNode extends Node {
		
		public var spatial:Spatial;
		public var life:Life;
		
		public var motion:Motion;
		public var collider:LandWeatherCollider;
		
	} // class
	
} // package