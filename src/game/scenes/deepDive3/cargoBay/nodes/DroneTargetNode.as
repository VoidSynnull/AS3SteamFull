package game.scenes.deepDive3.cargoBay.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.deepDive3.cargoBay.components.DroneTarget;
	
	public class DroneTargetNode extends Node
	{
		public var droneTarget:DroneTarget;
		public var display:Display;
		public var spatial:Spatial;
	}
}