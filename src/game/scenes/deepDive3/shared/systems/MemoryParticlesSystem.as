package game.scenes.deepDive3.shared.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.deepDive3.shared.nodes.MemoryParticlesNode;
	import game.systems.SystemPriorities;
	
	public class MemoryParticlesSystem extends ListIteratingSystem
	{
		public function MemoryParticlesSystem()
		{
			super(MemoryParticlesNode, updateNode);
			super._defaultPriority = SystemPriorities.render;
		}
		
		private function updateNode( node:MemoryParticlesNode, time:Number):void
		{
			node.memoryParticles.memoryParticleEmitter.attractToSpatial(node.targetSpatial.target);
		}
	}
}