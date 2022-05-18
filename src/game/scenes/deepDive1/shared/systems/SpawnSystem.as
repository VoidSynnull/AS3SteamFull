package game.scenes.deepDive1.shared.systems
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.ShellApi;
	
	import game.scenes.deepDive1.shared.components.Spawn;
	import game.scenes.deepDive1.shared.creators.SpawnFishCreator;
	import game.scenes.deepDive1.shared.nodes.SpawnNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	
	public class SpawnSystem extends GameSystem
	{
		public function SpawnSystem(creator:SpawnFishCreator)
		{
			super(SpawnNode, updateNode);
			_creator = creator;
		}
		
		public function updateNode(node:SpawnNode, time:Number):void
		{
			var spawn:Spawn = node.spawn;
			var x:Number;
			var y:Number;
			var reachedCap:Boolean = true;
			
			spawn._timeSinceLastSpawn += time;
			
			if(spawn.useSpawnCap)
			{
				if(spawn.totalFromThisSpawn < spawn.spawnCap)
				{
					reachedCap = false;	
				}
			}
			else if(_creator.getTotal(spawn.type) < spawn.max)
			{
				reachedCap = false;	
			}
			//super.log("total : "+ _creator.getTotal(spawn.type));
			if(spawn._timeSinceLastSpawn >= spawn.rate && !reachedCap)
			{
				spawn._timeSinceLastSpawn = 0;
				
				if(spawn.area)
				{
					var randomPosition:Point;
					
					if(spawn.outsideArea)
					{
						randomPosition = GeomUtils.getRandomPositionOutside(-spawn.distanceFromAreaEdge, -spawn.distanceFromAreaEdge, spawn.area.width + spawn.distanceFromAreaEdge, spawn.area.height + spawn.distanceFromAreaEdge);
						
						if(spawn.offsetAreaByCameraPosition)
						{
							x = -_shellApi.camera.x - _shellApi.viewportWidth * .5 + randomPosition.x;
							y = -_shellApi.camera.y - _shellApi.viewportHeight * .5 + randomPosition.y;
						}
					}
				}
				else
				{
					x = node.spatial.x;
					y = node.spatial.y;
					
					if(spawn.createRange)
					{
						x += (spawn.createRange.x - Math.random() * (spawn.createRange.x * 2));
						y += (spawn.createRange.y - Math.random() * (spawn.createRange.y * 2));
					}
				}
				
				spawn.totalFromThisSpawn++;
				var entity:Entity = _creator.createFromData(spawn.data, x, y);
				
				EntityUtils.addParentChild(entity, node.entity);
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(SpawnNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:SpawnFishCreator;
		[Inject]
		public var _shellApi:ShellApi;
	}
}