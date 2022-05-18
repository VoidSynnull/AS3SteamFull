package game.scenes.cavern1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.cavern1.shared.components.Magnetic;
	import game.scenes.cavern1.shared.components.MagneticData;
	
	public class MagneticNode extends Node
	{
		public var magnetic:Magnetic;
		public var magneticData:MagneticData;
		
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}