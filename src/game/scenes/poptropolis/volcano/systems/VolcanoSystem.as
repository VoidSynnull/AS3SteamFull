package game.scenes.poptropolis.volcano.systems 
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.volcano.nodes.IslandNode;
	import game.systems.SystemPriorities;
	
	public class VolcanoSystem extends System
	{
		private var _islands:NodeList;
		private var easing:Number = 0.15;
		private var island:IslandNode;
		private var spatial:Spatial;
		
		public function VolcanoSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_islands = systemManager.getNodeList( IslandNode );
		}
		
		override public function update( time:Number ):void
		{
			spatial = _islands.head.entity.get(Spatial);
			
			_islands.head.entity.get(Spatial).x = _islands.head.island.startX + randRange(-_islands.head.island.shakeAmount, _islands.head.island.shakeAmount);
			//_islands.head.entity.get(Spatial).y += randRange(-1, 1);
			if(!_islands.head.island.shake){
				if(_islands.head.island.shakeAmount > 0){
					_islands.head.island.shakeAmount -= .01;
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( IslandNode );
			_islands = null;
		}
		
		private function randRange(min:Number, max:Number):Number {
			var randomNum:Number = Math.floor(Math.random()*(max-min+1))+min;
				return randomNum;
		}
	}
}