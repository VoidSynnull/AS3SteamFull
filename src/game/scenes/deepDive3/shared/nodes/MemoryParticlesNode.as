package game.scenes.deepDive3.shared.nodes
{
	import ash.core.Node;
	
	import game.components.motion.TargetSpatial;
	import game.scenes.deepDive3.shared.components.MemoryParticlesComponent;
	
	public class MemoryParticlesNode extends Node
	{
		public var memoryParticles:MemoryParticlesComponent;
		public var targetSpatial:TargetSpatial;
	}
}