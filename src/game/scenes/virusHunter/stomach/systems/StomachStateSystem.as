package game.scenes.virusHunter.stomach.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.components.GameState;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.nodes.GameStateNode;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.scenes.virusHunter.stomach.Stomach;
	import game.scenes.virusHunter.stomach.components.StomachState;
	import game.scenes.virusHunter.stomach.cutscenes.SplinterCutScene;
	import game.scenes.virusHunter.stomach.nodes.StomachStateNode;
	import game.util.SceneUtil;
	
	public class StomachStateSystem extends System
	{
		private var scene:Stomach;
		private var events:VirusHunterEvents;
		
		private var _gameStateNodes:NodeList;
		private var _stomachStateNodes:NodeList;
		private var _killCountNodes:NodeList;
		
		public function StomachStateSystem(scene:Stomach, events:VirusHunterEvents)
		{
			this.scene = scene;
			this.events = events;
		}
		
		override public function update(time:Number):void
		{	
			var stomachStateNode:StomachStateNode = _stomachStateNodes.head as StomachStateNode;
			var gameStateNode:GameStateNode = _gameStateNodes.head as GameStateNode;
			var killCountNode:KillCountNode = _killCountNodes.head as KillCountNode;
			
			if(stomachStateNode && gameStateNode)
			{
				var gameState:GameState = gameStateNode.gameState;
				var state:StomachState = stomachStateNode.stomachState;
				var kills:KillCount = killCountNode.killCount;
				
				switch(state.state)
				{
					case state.STOMACH:
						break;
					case state.SPAWN_VIRUS:
						checkKills(state, kills, 15); //Set to 15
						break;
				}
			}
		}
		
		private function checkKills(state:StomachState, kills:KillCount, num:uint):void
		{
			if(kills.count["virus"] >= num)
			{
				kills.count["virus"] = 0;
				this.scene.virusSpawn.max = 0;
				state.state = state.STOMACH;
				
				this.scene.playMessage("missed_chance", true, null, "player", handlePopup);
			}
		}
		
		private function handlePopup():void
		{
			this.scene.shellApi.completeEvent(this.events.SPLINTER_CUTSCENE_PLAYED);
			
			var cutscene:SplinterCutScene = new SplinterCutScene(this.scene.overlayContainer);
			cutscene.removed.addOnce(handleRemoved);
			this.scene.addChildGroup(cutscene);
			
			SceneUtil.lockInput(this.group);
		}
		
		private function handleRemoved(...args):void
		{
			this.scene.playMessage("hand_warning", false, "hand_warning");
			SceneUtil.lockInput(this.group, false);
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_gameStateNodes = systemManager.getNodeList(GameStateNode);
			_stomachStateNodes = systemManager.getNodeList(StomachStateNode);
			_killCountNodes = systemManager.getNodeList(KillCountNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(StomachStateNode);
			super.removeFromEngine(systemManager);
		}
	}
}