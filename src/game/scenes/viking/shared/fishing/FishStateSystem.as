package game.scenes.viking.shared.fishing
{
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class FishStateSystem extends GameSystem
	{
		public function FishStateSystem()
		{
			super(FishNode, nodeUpdate, nodeAdd);
			this._defaultPriority = SystemPriorities.move;
		}
		
		public function nodeAdd(node:FishNode):void
		{
			//trace("FISH ADDED");
		}
		
		public function nodeUpdate(node:FishNode, time:Number):void
		{
			var fish:Fish = node.fish;
			switch(fish.state)
			{
				case Fish.IDLE:
				{
					updateIdle(node, time);
					break;
				}
				case Fish.SWIM:
				{
					updateSwim(node, time);
					break;
				}
				case Fish.FLOP:
				{
					// do nothing but animate, group processes rest of fishing
					updateFlop( node, time);
					break;
				}
			}
		}
		
		private function updateIdle(node:FishNode, time:Number):void
		{
			var fish:Fish = node.fish;
			fish.timeElapsed += time;
			if(fish.stateChanged){
				fish.stateChanged = false;
				node.timeline.gotoAndPlay(Fish.IDLE);
			}
			if(fish.timeElapsed > fish.idleTime){
				fish.state = Fish.SWIM;
				fish.timeElapsed = 0;
				fish.stateChanged = true;
			}
		}
		
		private function updateSwim(node:FishNode, time:Number):void
		{
			var fish:Fish = node.fish;
			if(fish.stateChanged){
				fish.stateChanged = false;
				node.timeline.gotoAndPlay(Fish.SWIM);
				if(fish.direction == "right"){
					if(node.spatial.x < node.origin.x + fish.range){
						moveRight(node);
					}
					else{
						moveLeft(node);
					}
				}
				else {
					if( node.spatial.x > node.origin.x - fish.range){
						moveLeft(node);
					}
					else{
						moveRight(node);
					}
				}
			}
		}
		
		private function moveRight(node:FishNode):void
		{
			var fish:Fish = node.fish;
			node.spatial.scaleX = -1;
			node.motion.velocity.x = fish.speed;
			node.threshHold.operator = ">";
			node.threshHold.threshold = node.spatial.x + fish.range * GeomUtils.randomInRange(0.5,1);
			node.threshHold.entered.addOnce(Command.create(swimComplete,node));
		}
		
		private function moveLeft(node:FishNode):void
		{
			var fish:Fish = node.fish;
			node.spatial.scaleX = 1;
			node.motion.velocity.x = -fish.speed;
			node.threshHold.operator = "<";
			node.threshHold.threshold = node.spatial.x - fish.range * GeomUtils.randomInRange(0.5,1);
			node.threshHold.entered.addOnce(Command.create(swimComplete,node));
		}
		
		private function swimComplete(node:FishNode):void
		{
			if(node.fish.direction == "right"){
				node.fish.direction = "left";
			}
			else{
				node.fish.direction = "right";
			}
			node.motion.zeroMotion();
			node.fish.state = Fish.IDLE;
		}
		
		private function updateFlop(node:FishNode, time:Number):void
		{
			var player:Entity = group.shellApi.player;
			CharacterMotionControl(player.get(CharacterMotionControl)).spinEnd = true;
			
			var fish:Fish = node.fish;
			if(fish.stateChanged){
				fish.stateChanged = false;
				node.timeline.gotoAndPlay(Fish.FLOP);
				node.motion.zeroMotion();
				node.threshHold.entered.removeAll();
			}
			// ensure no return to idle or swim
		}
	}
}