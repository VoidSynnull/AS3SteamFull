package game.scenes.poptropolis.wrestling.systems 
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.timeline.Timeline;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.poptropolis.wrestling.Wrestling;
	import game.scenes.poptropolis.wrestling.nodes.AttackBtnNode;
	import game.systems.SystemPriorities;
	
	public class WrestlingSystem extends System
	{
		private var _attackBtns:NodeList;
		private var attackBtn:AttackBtnNode;
		private var timeline:Timeline;		
				
		public function WrestlingSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_attackBtns = systemManager.getNodeList( AttackBtnNode );
			attackBtn = _attackBtns.head;
			timeline = attackBtn.entity.get(Timeline);
		}
		
		override public function update( time:Number ):void
		{
			if(attackBtn.attackBtn.spinning){
				if(attackBtn.attackBtn.counter % 5 == 0){
					if(timeline.currentIndex < 2){
						timeline.gotoAndStop(timeline.currentIndex+1);
					}else{
						timeline.gotoAndStop(0);
					}
				}
				if(attackBtn.attackBtn.counter < attackBtn.attackBtn.wait){
					attackBtn.attackBtn.counter++;
				}else{
					attackBtn.attackBtn.spinning = false;
					Wrestling(super.group).attackPicked();
				}
			}
			Wrestling(super.group).moveOpponent();
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( AttackBtnNode );
			_attackBtns = null;
		}
		
		private function randRange(min:Number, max:Number):Number {
			var randomNum:Number = Math.floor(Math.random()*(max-min+1))+min;
				return randomNum;
		}
	}
}