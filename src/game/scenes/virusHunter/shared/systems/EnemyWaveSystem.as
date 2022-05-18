package game.scenes.virusHunter.shared.systems
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.EnemyWaves;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.data.EnemyData;
	import game.scenes.virusHunter.shared.data.EnemyGroupData;
	import game.scenes.virusHunter.shared.data.EnemyWaveData;
	import game.scenes.virusHunter.shared.data.WaveEnemyData;
	import game.scenes.virusHunter.shared.nodes.EnemyWaveNode;
	import game.util.GeomUtils;
	
	public class EnemyWaveSystem extends ListIteratingSystem
	{
		public function EnemyWaveSystem(creator:EnemyCreator)
		{
			super(EnemyWaveNode, updateNode);
			
			_creator = creator;
		}
		
		public function updateNode(node:EnemyWaveNode, time:Number):void
		{
			if(_creator.getTotal() == 0)
			{
				createWave(node);
			}
		}
		
		private function createWave(node:EnemyWaveNode):void
		{
			var enemyWaves:EnemyWaves = node.enemyWaves;
			var spawn:EnemySpawn = node.spawn;
			var waveEnemyData:WaveEnemyData
			var randomPosition:Point;
			var x:Number;
			var y:Number;
			var allLevels:Dictionary;
			var enemyData:EnemyData;
			var enemyGroup:EnemyGroupData;
			var wave:EnemyWaveData;
			
			if(!enemyWaves.allDestroyed && !enemyWaves.pauseWaveCreation)
			{
				if(enemyWaves.waveIndex < enemyWaves.waves.length)
				{
					wave = enemyWaves.waves[enemyWaves.waveIndex];
					
					if(enemyWaves.groupIndex < wave.groups.length)
					{
						enemyGroup = wave.groups[enemyWaves.groupIndex];
						
						if(enemyGroup.boss && enemyWaves.pauseBeforeBossCreation)
						{
							if(enemyWaves.pauseBossCreation)
							{
								enemyWaves.pauseWaveCreation = true;
								enemyWaves.pauseBossCreation = false;
								enemyWaves.reachedBoss.dispatch(enemyWaves.waveIndex);
								return;
							}
						}
						
						if(enemyWaves.pauseBeforeBossCreation)
						{
							enemyWaves.pauseBossCreation = true;
						}
						
						for(var n:uint = 0; n < enemyGroup.enemies.length; n++)
						{
							waveEnemyData = enemyGroup.enemies[n];
							
							randomPosition = GeomUtils.getRandomPositionOutside(-spawn.distanceFromAreaEdge, -spawn.distanceFromAreaEdge, spawn.area.width + spawn.distanceFromAreaEdge, spawn.area.height + spawn.distanceFromAreaEdge);
							x = -_shellApi.camera.x - _shellApi.viewportWidth * .5 + randomPosition.x;
							y = -_shellApi.camera.y - _shellApi.viewportHeight * .5 + randomPosition.y;
							
							allLevels = _creator.allEnemyData[waveEnemyData.type];
							
							if(allLevels)
							{
								enemyData = allLevels[waveEnemyData.level];
								
								_creator.createFromData(enemyData, x, y, randomPosition);
							}
						}
						
						enemyWaves.groupIndex++;
					}
					else
					{
						enemyWaves.groupIndex = 0;
						enemyWaves.waveIndex++;
						
						if(enemyWaves.pauseAfterWaveDestroyed)
						{
							enemyWaves.pauseWaveCreation = true;
						}
						enemyWaves.waveDestroyed.dispatch(enemyWaves.waveIndex);
					}
				}
				else
				{
					enemyWaves.allWavesDestroyed.dispatch();
					enemyWaves.allDestroyed = true;
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(EnemyWaveNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
		[Inject]
		public var _shellApi:ShellApi;
	}
}