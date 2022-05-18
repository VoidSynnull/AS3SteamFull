package game.scenes.poptropolis.weightLift.systems 
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.weightLift.components.Weight;
	import game.scenes.poptropolis.weightLift.nodes.WeightNode;
	import game.scenes.poptropolis.weightLift.WeightLift;
	import game.systems.SystemPriorities;
	
	public class WeightSystem extends System
	{
		private var _weights:NodeList;
		private var angle:Number = 0;
		private var counter:Number = 0;
		private var weight:WeightNode;
		private var spatial:Spatial;
		
		public function WeightSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_weights = systemManager.getNodeList( WeightNode );
			weight = _weights.head;
			spatial= weight.entity.get(Spatial);
		}
		
		override public function update( time:Number ):void
		{
			if(weight.weight.lifting){
				spatial.rotation = Math.sin(angle);
				angle+=.5;
				WeightLift(super.group).movePlayer();
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( WeightNode );
			_weights = null;
		}
		
		private function randRange(min:Number, max:Number):Number {
			var randomNum:Number = Math.floor(Math.random()*(max-min+1))+min;
				return randomNum;
		}
	}
}