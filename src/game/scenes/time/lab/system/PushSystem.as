package game.scenes.time.lab.system
{	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.scenes.time.lab.components.PushComponent;
	import game.scenes.time.lab.nodes.PushNode;
	import game.systems.GameSystem;
	
	public class PushSystem extends GameSystem
	{
		public function PushSystem()
		{
			super(PushNode,updateNode,addNode);
		}
		
		private function addNode(node:PushNode):void
		{
			var ent:Entity = node.entity;
			var push:PushComponent = node.push;
			
		}
		
		private function updateNode(node:PushNode, time:Number):void
		{
			var ent:Entity = node.entity;
			var push:PushComponent = node.push;
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			var playerMotion:Motion = group.shellApi.player.get(Motion);
			var charMotControl:CharacterMotionControl = CharacterMotionControl(group.shellApi.player.get(CharacterMotionControl))
			// move
			if(push.pushing){
				charMotControl.spinStopped = true;
				charMotControl.maxVelocityX = 150;
				playerMotion.velocity.x = 150;
				playerMotion.acceleration.x = 0;
				playerMotion.acceleration.y =0;
				if(motion.x > push.endX){
					motion.x = push.endX;
					endPush(node);
				}
				else if(push.direction == "right"){
					motion.velocity.x = Math.abs(playerMotion.velocity.x);
					motion.velocity.y = 0;
					if(push.pushZone){
						push.pushZone.get(Display).displayObject.x = motion.x;
					}
				}else{
					motion.velocity.x = -Math.abs(playerMotion.velocity.x);
					motion.velocity.y = 0;
					if(push.pushZone){
						push.pushZone.get(Display).displayObject.x = motion.x;
					}
				}
			}
		}
		
		private function endPush(node:PushNode):void
		{
			var push:PushComponent = node.push;
			var motion:Motion = node.motion;
			push.pushing = false;
			push.endReached.dispatch();
			motion.velocity.x = 0;
			motion.velocity.y = 0;
		}
		
	}
}