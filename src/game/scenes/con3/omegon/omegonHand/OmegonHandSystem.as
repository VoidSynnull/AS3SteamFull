package game.scenes.con3.omegon.omegonHand
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Bounce;
	
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.hit.Hazard;
	import game.components.hit.Platform;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.con3.omegon.omegonLaserControl.OmegonLaserControl;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	public class OmegonHandSystem extends GameSystem
	{
		public function OmegonHandSystem()
		{
			super(OmegonHandNode, updateNode);
		}
		
		private function updateNode(node:OmegonHandNode, time:Number):void
		{
			if(node.hand._invalidate)
			{
				node.hand._invalidate = false;
				
				if(node.hand.state == "attack")
				{
					this.prepAttack(node);
				}
				else if(node.hand.state == "pulsed")
				{
					this.moveToFuse(node);
				}
				else if(node.hand.state == "damaged")
				{
					this.moveToDamaged(node);
				}
				
				node.hand.stateChanged.dispatch(node.entity);
			}
		}
		
		private function prepAttack(node:OmegonHandNode):void
		{
			if(node.hand.state != "attack") return;
			
			AudioUtils.play(node.entity.group, SoundManager.EFFECTS_PATH + "event_11.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			node.tween.killAll();
			node.tween.to(node.spatial, 1.5, {y:725, onComplete:moveToAttack, onCompleteParams:[node]});
		}
		
		private function moveToAttack(node:OmegonHandNode):void
		{
			if(node.hand.state != "attack") return;
			
			node.tween.killAll();
			node.tween.to(node.spatial, 0.5, {y:1070, ease:Back.easeInOut, onComplete:moveToAttackComplete, onCompleteParams:[node]});
		}
		
		private function moveToAttackComplete(node:OmegonHandNode):void
		{
			if(node.hand.state != "attack") return;
			
			node.tween.killAll();
			node.tween.to(node.spatial, 0.85, {y:750, ease:Back.easeOut, onComplete:waitToAttack, onCompleteParams:[node]});
		}
		
		private function waitToAttack(node:OmegonHandNode):void
		{
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(5, 1, Command.create(prepAttack, node)));
		}
		
		private function moveToDamaged(node:OmegonHandNode):void
		{
			node.tween.killAll();
			node.tween.to(node.spatial, Math.abs(node.spatial.y - 1080) / 400, {y:1080, ease:Bounce.easeOut});
			node.hand.hand_platform.add(node.hand.removedPlatform);
			node.hand.removedHazard = node.hand.hand_hazard.remove(Hazard) as Hazard;
		}
		
		private function moveToFuse(node:OmegonHandNode):void
		{
			node.tween.killAll();
			node.tween.to(node.spatial, 7, {y:460, onComplete:moveToFuseComplete, onCompleteParams:[node]});
		}
		
		private function moveToFuseComplete(node:OmegonHandNode):void
		{
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(3, 1, Command.create(moveLaserToPlayer, node)));
		}
		
		private function moveLaserToPlayer(node:OmegonHandNode):void
		{
			OmegonLaserControl(node.hand.laser_control.get(OmegonLaserControl)).isLeft = node.hand.isLeft;
			OmegonLaserControl(node.hand.laser_control.get(OmegonLaserControl)).state = "hand";
			
			SceneUtil.addTimedEvent(node.entity.group, new TimedEvent(5, 1, Command.create(moveToRepair, node)));
		}
		
		private function moveToRepair(node:OmegonHandNode):void
		{
			node.tween.to(node.spatial, 1, {y:230, onComplete:moveToRepairComplete, onCompleteParams:[node]});
			node.hand.removedPlatform = node.hand.hand_platform.remove(Platform) as Platform;
		}
		
		private function moveToRepairComplete(node:OmegonHandNode):void
		{
			node.hand.hand_platform.add(node.hand.removedPlatform);
			node.hand.hand_hazard.add(node.hand.removedHazard);
			Timeline(node.hand.power_source.get(Timeline)).gotoAndStop("on");
			
			node.tween.to(node.spatial, 3, {y:750, onComplete:moveToGroundComplete, onCompleteParams:[node]});
		}
		
		private function moveToGroundComplete(node:OmegonHandNode):void
		{
			node.hand.state = "attack";
		}
	}
}