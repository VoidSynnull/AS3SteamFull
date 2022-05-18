package game.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.DynamicSystem;
	import engine.components.SpatialOffset;
	import engine.managers.GroupManager;
	
	import game.nodes.ParticleNode;
	import game.util.EntityUtils;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.twoD.emitters.Emitter2D;

	public class ParticleSystem extends DynamicSystem
	{
		private var nodes : NodeList;

		override public function addToEngine( gameSystems : Engine ) : void
		{
			nodes = gameSystems.getNodeList( ParticleNode );
			nodes.nodeRemoved.add(nodeRemoved);
			super._defaultPriority = SystemPriorities.move;
		}
		
		override public function update( time : Number ) : void
		{
			var node:ParticleNode;
			var emitter:Emitter2D;
			var offset:SpatialOffset;
			
			for ( node = nodes.head; node; node = node.next )
			{
				if (EntityUtils.sleeping(node.entity))
				{
					if(node.emitter.removeOnSleep)
					{
						_groupManager.removeEntity(node.entity);
					}
					
					continue;
				}
				
				emitter = node.emitter.emitter;
				
				if (emitter != null)
				{					
					emitter.x = node.spatial.x;
					emitter.y = node.spatial.y;
					emitter.rotation = node.spatial.rotation;
					
					offset = node.entity.get(SpatialOffset);
					
					if(offset != null)
					{
						emitter.x = node.spatial.x + offset.x;
						emitter.y = node.spatial.y + offset.y;
						emitter.rotation = node.spatial.rotation + offset.rotation;
					}
					
					if( node.emitter.start )
					{
						node.emitter.start = false;
						emitter.start();
					}
					
					if( node.emitter.pause )
					{
						node.emitter.pause = false;
						emitter.pause();
					}
					
					if( node.emitter.resume )
					{
						node.emitter.resume = false;
						emitter.resume();
					}
					
					if( node.emitter.stop )
					{
						node.emitter.stop = false;
						emitter.stop();
					}
					
					emitter.update(time);
					
					if(node.emitter.remove)
					{
						// TODO : Add removal for other counter types.
						if(emitter.counter is Steady)
						{
							Steady(emitter.counter).rate = 0;
						}
						else if (emitter.counter is Random)
						{
							Random(emitter.counter).stop();
						}
						
						if(emitter.particles.length == 0)
						{
							_groupManager.removeEntity(node.entity);
						}
					}
				}
			}
		}
		
		private function nodeRemoved(node:ParticleNode):void
		{
			node.emitter.emitter.stop();
			node.emitter.emitter.removeAllInitializers();
		}
						
		override public function removeFromEngine( gameSystems : Engine ) : void
		{
			gameSystems.releaseNodeList( ParticleNode );
			nodes = null;
		}
		
		[Inject]
		public var _groupManager:GroupManager;
	}
}
