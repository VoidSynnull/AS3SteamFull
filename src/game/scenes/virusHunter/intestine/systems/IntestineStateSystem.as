package game.scenes.virusHunter.intestine.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.group.Scene;
	
	import game.scenes.virusHunter.intestine.Intestine;
	import game.scenes.virusHunter.intestine.components.IntestineState;
	import game.scenes.virusHunter.intestine.nodes.IntestineStateNode;
	import game.scenes.virusHunter.shared.components.GameState;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.GameStateNode;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	
	public class IntestineStateSystem extends System
	{
		private var _scene:Intestine;
		
		private var _creator:EnemyCreator;
		private var _gameStateNodes:NodeList;
		private var _intestineStateNodes:NodeList;
		private var _killCountNodes:NodeList;
		
		public function IntestineStateSystem(scene:Scene)
		{
			_scene = scene as Intestine;
		}
		
		override public function update(time:Number):void
		{	
			var intestineStateNode:IntestineStateNode = _intestineStateNodes.head as IntestineStateNode;
			var gameStateNode:GameStateNode = _gameStateNodes.head as GameStateNode;
			var killCountNode:KillCountNode = _killCountNodes.head as KillCountNode;
			
			if(intestineStateNode && gameStateNode)
			{
				var gameState:GameState = gameStateNode.gameState;
				var state:IntestineState = intestineStateNode.intestineState;
				var kills:KillCount = killCountNode.killCount;
				
				switch(state.state)
				{
					case state.INTESTINE: break;
					case state.SPAWN_VIRUS_1:
						checkKills(state, kills, 1);
						break;
					case state.SPAWN_VIRUS_2:
						checkKills(state, kills, 2);
						break;
					case state.SPAWN_VIRUS_3:
						checkKills(state, kills, 3);
						break;
				}
			}
		}
		
		private function checkKills(state:IntestineState, kills:KillCount, num:uint):void
		{
			if(kills.count["virus"] >= num * 2)
			{
				kills.count["virus"] = 0;
				_scene.virusSpawn.max = 0;
				state.state = state.INTESTINE;
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_gameStateNodes = systemManager.getNodeList(GameStateNode);
			_intestineStateNodes = systemManager.getNodeList(IntestineStateNode);
			_killCountNodes = systemManager.getNodeList(KillCountNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(IntestineStateNode);
			super.removeFromEngine(systemManager);
		}
	}
}