package game.scenes.virusHunter.shared.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.ShellApi;
	
	import game.scenes.virusHunter.shared.components.GameState;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.GameStateNode;
	import game.scenes.virusHunter.shared.nodes.RedBloodCellMotionNode;
	import game.scenes.virusHunter.shared.nodes.VirusMotionNode;

	public class ShipGameManagerSystem extends System
	{
		public function ShipGameManagerSystem(creator:EnemyCreator)
		{
			_creator = creator;
		}
		
		override public function update(time:Number):void
		{
			var gameStateNode:GameStateNode = _gameStateNodes.head as GameStateNode;
			
			if(gameStateNode)
			{
				var gameState:GameState = gameStateNode.gameState;
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_virusNodes = systemManager.getNodeList(VirusMotionNode);
			_redBloodCellNodes = systemManager.getNodeList(RedBloodCellMotionNode);
			_gameStateNodes = systemManager.getNodeList(GameStateNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(GameStateNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
		private var _virusNodes:NodeList;
		private var _gameStateNodes:NodeList;
		private var _redBloodCellNodes:NodeList;
		
		[Inject]
		public var _shellApi:ShellApi;
	}
}