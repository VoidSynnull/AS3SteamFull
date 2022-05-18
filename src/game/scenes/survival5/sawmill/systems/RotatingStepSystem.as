package game.scenes.survival5.sawmill.systems
{
	import engine.components.Motion;
	
	import game.components.hit.CurrentHit;
	import game.scenes.survival5.sawmill.components.RotatingStep;
	import game.scenes.survival5.sawmill.nodes.RotatingStepNode;
	import game.systems.GameSystem;
	
	public class RotatingStepSystem extends GameSystem
	{
		public function RotatingStepSystem()
		{
			super(RotatingStepNode, updateNode);
		}
		
		private function updateNode(node:RotatingStepNode, time:Number):void
		{
			var rotatingStep:RotatingStep = node.rotatingStep;
			var platformMotion:Motion = rotatingStep.platform.get(Motion);
			var playerHit:CurrentHit = this.group.shellApi.player.get(CurrentHit);
			
			if(playerHit.hit == rotatingStep.platform)
			{
				if(node.spatial.rotation < rotatingStep.maxRotation)
				{
					node.motion.rotationVelocity = rotatingStep.speed/2;
					platformMotion.rotationVelocity = rotatingStep.speed/2;
					rotatingStep.gear1.rotationVelocity = rotatingStep.speed*2;
					rotatingStep.gear2.rotationVelocity = -rotatingStep.speed*2;	
				}
				else if(node.motion.rotationVelocity != 0)
				{
					node.motion.rotationVelocity = 0;
					platformMotion.rotationVelocity = 0;
					rotatingStep.gear1.rotationVelocity = 0;
					rotatingStep.gear2.rotationVelocity = 0;	
					rotatingStep.trapSet.dispatch();
				}			
							
				rotatingStep.saw.rotationVelocity = 0;
				rotatingStep.attachedGear.rotationVelocity = 0;
			}
			else
			{
				if(node.spatial.rotation > 0)
				{
					node.motion.rotationVelocity = -rotatingStep.speed;
					platformMotion.rotationVelocity = -rotatingStep.speed;	
					rotatingStep.gear1.rotationVelocity = rotatingStep.speed*2;
					rotatingStep.gear2.rotationVelocity = -rotatingStep.speed*2;
				}
				else
				{
					node.motion.rotationVelocity = 0;
					platformMotion.rotationVelocity = 0;
					rotatingStep.gear1.rotationVelocity = 0;
					rotatingStep.gear2.rotationVelocity = 0;
					
					if(rotatingStep.gearAttached)
					{
						rotatingStep.saw.rotationVelocity = -rotatingStep.speed;
						rotatingStep.attachedGear.rotationVelocity = -rotatingStep.speed;
					}
				}
			}
		}
	}
}