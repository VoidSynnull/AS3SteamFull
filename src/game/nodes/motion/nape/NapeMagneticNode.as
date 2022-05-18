package game.nodes.motion.nape
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.Magnetic;
	import game.components.motion.nape.NapeMotion;
	
	public class NapeMagneticNode extends Node
	{
		public var spatial:Spatial;
		public var magnetic:Magnetic;
		public var napeMotion:NapeMotion;
		public var motion:Motion;
		public var optional:Array = [NapeMotion];
	}
}