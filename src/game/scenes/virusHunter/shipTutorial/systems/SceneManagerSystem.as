package game.scenes.virusHunter.shipTutorial.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.GameState;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.nodes.GameStateNode;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.scenes.virusHunter.shipTutorial.ShipTutorial;
	import game.scenes.virusHunter.shipTutorial.components.SceneState;
	import game.scenes.virusHunter.shipTutorial.nodes.SceneStateNode;
	
	public class SceneManagerSystem extends System
	{
		public function SceneManagerSystem(scene:ShipTutorial, creator:EnemyCreator)
		{
			_scene = scene;
			_creator = creator;
		}
		
		override public function update(time:Number):void
		{	
			var sceneStateNode:SceneStateNode = _sceneStateNodes.head as SceneStateNode;
			var gameStateNode:GameStateNode = _gameStateNodes.head as GameStateNode;
			
			if(sceneStateNode && gameStateNode)
			{
				var gameState:GameState = gameStateNode.gameState;
				var sceneState:SceneState = sceneStateNode.sceneState;
				
				if(sceneState.state == sceneState.SPAWN_VIRUS)
				{
					var killCountNode:KillCountNode = _killCountNodes.head;
					
					if(killCountNode.killCount.count[EnemyType.VIRUS] > sceneState.TOTAL_VIRUS)
					{
						var virusSpawn:Entity = _scene.getEntityById(EnemyType.VIRUS);
						var spawn:EnemySpawn = virusSpawn.get(EnemySpawn);
						spawn.max = 0;
						sceneState.state = sceneState.ELIMINATE_VIRUS;
					}
				}
				else if(sceneState.state == sceneState.ELIMINATE_VIRUS)
				{
					if(_creator.getTotal(EnemyType.VIRUS) == 0)
					{
						sceneState.wait = sceneState.LEAVE_SCENE_WAIT;
						sceneState.state = sceneState.FINAL_DIALOG;
						_scene.playMessage("end");
					}
				}
				else if(sceneState.state == sceneState.LEAVE_TUTORIAL)
				{
					if(sceneState.wait <= 0)
					{
						sceneState.state = null;
						_scene.shellApi.completeEvent(VirusHunterEvents(_scene.shellApi.islandEvents).COMPLETED_TUTORIAL);
						_scene.shellApi.loadScene(sceneState.nextScene);
					}
					else
					{
						sceneState.wait -= time;
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_gameStateNodes = systemManager.getNodeList(GameStateNode);
			_sceneStateNodes = systemManager.getNodeList(SceneStateNode);
			_killCountNodes = systemManager.getNodeList(KillCountNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SceneStateNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
		private var _gameStateNodes:NodeList;
		private var _sceneStateNodes:NodeList;
		private var _killCountNodes:NodeList;
		
		
		private var _scene:ShipTutorial;
	}
}