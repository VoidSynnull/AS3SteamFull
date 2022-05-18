package game.scenes.virusHunter.foreArm.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.entity.Parent;
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.foreArm.components.BossSpawn;
	import game.scenes.virusHunter.foreArm.components.ForeArmState;
	import game.scenes.virusHunter.foreArm.nodes.BossSpawnNode;
	import game.scenes.virusHunter.foreArm.nodes.ForeArmStateNode;
	import game.scenes.virusHunter.shared.components.EvoVirus;
	import game.scenes.virusHunter.shared.nodes.GameStateNode;
	
	public class ForeArmBossSystem extends ListIteratingSystem
	{
		public function ForeArmBossSystem()
		{
			super( BossSpawnNode, updateNode );
		}
		
		private function updateNode( node:BossSpawnNode, time:Number ):void
		{
			var foreArmStateNode:ForeArmStateNode = _foreArmStateNodes.head as ForeArmStateNode;
			var foreArmState:ForeArmState = foreArmStateNode.foreArmState;
			
			var bossSpawn:BossSpawn = node.bossSpawn; 
			var spatial:Spatial = node.spatial;
			var timeline:Timeline = node.timeline;
			var kids:Children = node.children;
			
			var entity:Entity;
			var virus:EvoVirus;
			
			if( foreArmState.state == foreArmState.BATTLE )
			{				
				if( node.bossSpawn.bossState != node.bossSpawn.WOUNDED && node.bossSpawn.bossState != node.bossSpawn.DEAD && node.bossSpawn.bossState != node.bossSpawn.HIT )
				{
					if( kids.children.length < MAX_KIDS )
					{
						if( bossSpawn.bossState != bossSpawn.SPAWN )
						{
							bossSpawn.bossState = bossSpawn.SPAWN;
							timeline.gotoAndPlay( "spawn" );
							group.shellApi.triggerEvent( _events.SPAWN_EVOVIRUS );
						}	
					}
					
					var length:int = kids.children.length;
					
					for( var number:int = 0; number < length; number ++ )
					{
						entity = kids.children.pop();
						virus = entity.get( EvoVirus );
						if( !virus )
						{
							entity.remove( Parent );
						}
						
						else
						{
							kids.children.push( entity );
						}
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_gameStateNodes = systemManager.getNodeList( GameStateNode );
			_foreArmStateNodes = systemManager.getNodeList( ForeArmStateNode );
			_events = group.shellApi.islandEvents as VirusHunterEvents;
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine( systemManager:Engine ) : void
		{
			systemManager.releaseNodeList( ForeArmStateNode );
		}
		
		private const MAX_KIDS:int =1;
		private var _events:VirusHunterEvents;
				
		private var _gameStateNodes:NodeList;
		private var _foreArmStateNodes:NodeList;
		private var _evoVirusNodes:NodeList;
	}
}