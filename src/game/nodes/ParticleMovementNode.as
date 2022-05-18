package game.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.components.ParticleMovement;

	public class ParticleMovementNode extends Node
	{
		public var spatial:Spatial;
		public var emitter:Emitter;
		public var particleMovement:ParticleMovement;
	}
}