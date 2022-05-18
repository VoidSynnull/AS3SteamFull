package game.systems.entity.character
{
	import ash.core.Engine;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterWander;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Walk;
	import game.nodes.entity.character.CharacterWanderNode;
	import game.systems.GameSystem;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.Utils;
	
	public class CharacterWanderSystem extends GameSystem
	{
		public function CharacterWanderSystem()
		{
			super(CharacterWanderNode, updateNode, nodeAdded);
		}
		
		private function updateNode(node:CharacterWanderNode, time:Number):void
		{
			var wander:CharacterWander = node.characterWander;
			
			if (wander.disabled)
				return;
			
			if(wander.pause)
			{
				if(wander.state != wander.PAUSED)
				{
					halt(node, wander.PAUSED);
				}
			}
			else if(wander.state == wander.PAUSED)
			{
				wander.state = wander.WAIT;
			}
			
			if(wander.state != wander.PAUSED)
			{
				switch(wander.state)
				{
					case wander.WAIT :
						wait(node, time);
					break;
					
					case wander.START_MOVE :
						startMove(node);
					break;
					
					case wander.MOVE :
						move(node);
					break;
				}
			}
		}
		
		private function wait(node:CharacterWanderNode, time:Number):void
		{
			var wander:CharacterWander = node.characterWander;
			
			if(wander.remainingWaitTime > 0)
			{
				wander.remainingWaitTime -= time;
			}
			else
			{
				wander.remainingWaitTime = 0;
				wander.state = wander.START_MOVE;
			}
		}
		
		private function startMove(node:CharacterWanderNode):void
		{
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			var wander:CharacterWander = node.characterWander;
			var accelerationX:Number = 0;
			var accelerationY:Number = 0;

			if(wander.rangeX > 0)
			{
				wander._targetX = wander._initX + Utils.randNumInRange(-wander.rangeX, wander.rangeX);
				
				if(wander._targetX > spatial.x)
				{
					accelerationX = wander.acceleration;
					spatial.scaleX = -spatial.scale;
				}
				else if(wander._targetX < spatial.x)
				{
					accelerationX = -wander.acceleration;
					spatial.scaleX = spatial.scale;
				}
			}
			
			if(wander.rangeY > 0)
			{
				wander._targetY = wander._initY + Utils.randNumInRange(-wander.rangeY, wander.rangeY);
				
				if(wander._targetY > spatial.y)
				{
					accelerationY = wander.acceleration;
				}
				else if(wander._targetY < spatial.y)
				{
					accelerationY = -wander.acceleration;
				}
			}
			
			motion.acceleration.x = accelerationX;
			motion.acceleration.y = accelerationY;
			
			wander.state = wander.MOVE;
			
			CharUtils.setAnim(node.entity, Walk, false);
		}
		
		private function move(node:CharacterWanderNode):void
		{
			var outOfRange:Boolean = false;
			var wander:CharacterWander = node.characterWander;
			
			if(wander.rangeX > 0)
			{
				if((node.motion.velocity.x > 0 && node.spatial.x > wander._targetX) || (node.motion.velocity.x < 0 && node.spatial.x < wander._targetX))
				{
					outOfRange = true;
				}
			}
			
			if(wander.rangeY > 0)
			{
				if((node.motion.velocity.y > 0 && node.spatial.y > wander._targetY) || (node.motion.velocity.y < 0 && node.spatial.y < wander._targetY))
				{
					outOfRange = true;
				}
			}
			
			if(outOfRange)
			{
				halt(node, wander.WAIT);
			}
		}
		
		private function halt(node:CharacterWanderNode, state:String):void
		{
			var wander:CharacterWander = node.characterWander;
			
			MotionUtils.zeroMotion(node.entity);
			wander.state = state;
			
			if(state == wander.WAIT)
			{
				wander.remainingWaitTime = Utils.randNumInRange(wander.minTimeToWait, wander.maxTimeToWait);
			}
			
			CharUtils.setAnim(node.entity, Stand, false);
		}
		
		private function nodeAdded(node:CharacterWanderNode):void
		{
			var wander:CharacterWander = node.characterWander;
			
			wander._initX = node.spatial.x;
			wander._initY = node.spatial.y;
			wander.state = wander.WAIT;
			wander.remainingWaitTime = Utils.randNumInRange(wander.minTimeToWait, wander.maxTimeToWait);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(CharacterWanderNode);
			super.removeFromEngine(systemManager);
		}
	}
}