package game.scenes.deepDive3.shared.components
{
	import ash.core.Component;
	
	import game.scenes.deepDive3.shared.particles.MemoryParticles;
	
	public class MemoryParticlesComponent extends Component
	{
		public function MemoryParticlesComponent( memoryParticleEmitter:MemoryParticles):void
		{
			this.memoryParticleEmitter = memoryParticleEmitter;
		}
		
		public var memoryParticleEmitter:MemoryParticles;
	}
}