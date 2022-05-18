package game.scenes.con3.omegon.omegonLaserControl
{
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.ShakeMotion;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.con3.omegon.OmegonLaserArm;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	public class OmegonLaserControlSystem extends GameSystem
	{
		public function OmegonLaserControlSystem()
		{
			super(OmegonLaserControlNode, updateNode);
		}
		
		private function updateNode(node:OmegonLaserControlNode, time:Number):void
		{
			if(node.laser._invalidate)
			{
				node.laser._invalidate = false;
				
				node.tween.killAll();
				
				ShakeMotion(node.laser.laser_arm_left.get(ShakeMotion)).active = false;
				ShakeMotion(node.laser.laser_arm_right.get(ShakeMotion)).active = false;
				
				if(node.laser.state == "hand")
				{
					if(node.laser.isLeft)
					{
						this.moveLaserArmToHand(node, node.laser.laser_arm_left);
						this.moveLaserArmToIdle(node, node.laser.laser_arm_right);
					}
					else
					{
						this.moveLaserArmToHand(node, node.laser.laser_arm_right);
						this.moveLaserArmToIdle(node, node.laser.laser_arm_left);
					}
				}
				else if(node.laser.state == "ground")
				{
					this.moveLaserArms(node);
				}
			}
		}
		
		private function moveLaserArms(node:OmegonLaserControlNode):void
		{
			if(node.laser.state != "ground") return;
			
			if(node.laser.laser_arm_left.get(Spatial).y < node.laser.laser_arm_right.get(Spatial).y)
			{
				this.moveLaserArmDown(node, node.laser.laser_arm_left);
				this.moveLaserArmUp(node, node.laser.laser_arm_right);
			}
			else
			{
				this.moveLaserArmDown(node, node.laser.laser_arm_right);
				this.moveLaserArmUp(node, node.laser.laser_arm_left);
			}
		}
		
		private function moveLaserArmToHand(node:OmegonLaserControlNode, arm:Entity):void
		{
			var omegonLaserArm:OmegonLaserArm = arm.get(OmegonLaserArm);
			
			Timeline(omegonLaserArm.laser.get(Timeline)).gotoAndPlay("off");
			
			node.tween.to(arm.get(Spatial), 2, {y:omegonLaserArm.hand.get(Spatial).y - 60, onComplete:moveLaserArmToHandComplete, onCompleteParams:[node, arm]});
		}
		
		private function moveLaserArmToHandComplete(node:OmegonLaserControlNode, arm:Entity):void
		{
			var omegonLaserArm:OmegonLaserArm = arm.get(OmegonLaserArm);
			
			Timeline(omegonLaserArm.laser.get(Timeline)).gotoAndPlay("on");
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(1.5, 1, Command.create(moveLaserToGround, node, arm)));
		}
		
		private function moveLaserArmToIdle(node:OmegonLaserControlNode, arm:Entity):void
		{
			var omegonLaserArm:OmegonLaserArm = arm.get(OmegonLaserArm);
			
			Timeline(omegonLaserArm.laser.get(Timeline)).gotoAndPlay("off");
		}
		
		private function moveLaserToGround(node:OmegonLaserControlNode, arm:Entity):void
		{
			var omegonLaserArm:OmegonLaserArm = arm.get(OmegonLaserArm);
			
			Timeline(omegonLaserArm.laser.get(Timeline)).gotoAndPlay("off");
			node.laser.state = "ground";
		}
		
		private function moveLaserArmUp(node:OmegonLaserControlNode, arm:Entity):void
		{
			node.tween.to(arm.get(Spatial), 2, {y:800});
		}
		
		private function moveLaserArmDown(node:OmegonLaserControlNode, arm:Entity):void
		{
			if(node.laser.state != "ground") return;
			
			node.tween.to(arm.get(Spatial), 2, {y:1110, onComplete:moveLaserArmDownComplete, onCompleteParams:[node, arm]});
		}
		
		private function moveLaserArmDownComplete(node:OmegonLaserControlNode, arm:Entity):void
		{
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(1, 1, Command.create(startShake, arm)));
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(2, 1, Command.create(turnLaserOn, node, arm)));
		}
		
		private function startShake(arm:Entity):void
		{
			AudioUtils.play(arm.group, SoundManager.EFFECTS_PATH + "event_11.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			ShakeMotion(arm.get(ShakeMotion)).active = true;
		}
		
		private function turnLaserOn(node:OmegonLaserControlNode, arm:Entity):void
		{
			if(node.laser.state != "ground") return;
			
			ShakeMotion(arm.get(ShakeMotion)).active = false;
			
			var omegonLaserArm:OmegonLaserArm = arm.get(OmegonLaserArm);
			
			var timeline:Timeline = omegonLaserArm.laser.get(Timeline);
			timeline.gotoAndPlay("on");
			
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(0.5, 1, Command.create(turnLaserOff, node, arm)));
		}
		
		private function turnLaserOff(node:OmegonLaserControlNode, arm:Entity):void
		{
			if(node.laser.state != "ground") return;
			
			var omegonLaserArm:OmegonLaserArm = arm.get(OmegonLaserArm);
			
			var timeline:Timeline = omegonLaserArm.laser.get(Timeline);
			timeline.gotoAndPlay("off");
			
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(0.5, 1, Command.create(this.moveLaserArms, node)));
			
			//this.moveLaserArms(node);
		}
	}
}