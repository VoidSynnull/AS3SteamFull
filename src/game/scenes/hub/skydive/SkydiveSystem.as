package game.scenes.hub.skydive
{
	import engine.components.Motion;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Jump;
	import game.data.animation.entity.character.Stand;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	
	public class SkydiveSystem extends GameSystem
	{
		public function SkydiveSystem()
		{
			super(SkydiveNode, updateNode);
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		private function updateNode(node:SkydiveNode, time:Number):void
		{
			if(node.playerState.state == PlayerState.WIN || node.playerState.state == PlayerState.LOSE)
			{
				var rig:RigAnimation = node.entity.get(RigAnimation);
				
				if(node.playerState.state == PlayerState.WIN && !(rig.current is Stand))
				{
					CharUtils.setAnim(node.entity, Stand);
				}
				else if(node.playerState.state == PlayerState.LOSE && !(rig.current is Dizzy))
				{
					CharUtils.setAnim(node.entity, Dizzy);
				}
			}
			
			if(node.playerState._invalidate)
			{
				var motion:Motion = node.motion;
				
				switch(node.playerState.state)
				{
					case PlayerState.FALL :
						motion.velocity.y = -300;
						motion.acceleration.y = 900;
						
						CharUtils.setAnim(node.entity, Jump);
						break;
					
					case PlayerState.DEPLOY_CHUTE :
						updateChute(node, "deploy");
						node.audio.playCurrentAction("chuteOpened");
						break;
					
					case PlayerState.FLOAT :
						updateChute(node, "deployed");
						motion.velocity.y = 200;
						motion.acceleration.y = 0;
						node.audio.playCurrentAction("chuteDeployed");
						break;
					
					case PlayerState.LAND :
						changePlayerState(node, PlayerState.WIN);
						updateChute(node, "land");
						node.audio.playCurrentAction("landed");
						break;
					
					case PlayerState.CRASH :
						changePlayerState(node, PlayerState.LOSE);
						updateChute(node, "remove");
						node.audio.playCurrentAction("crashed");
						break;
				}
				
				node.playerState._invalidate = false;
			}
			else
			{
				if(node.motionBounds.bottom && (node.playerState.state == PlayerState.FLOAT || node.playerState.state == PlayerState.FALL || node.playerState.state == PlayerState.DEPLOY_CHUTE))
				{
					if(node.playerState.state == PlayerState.FLOAT)
					{
						CharUtils.setAnim(node.entity, Stand);
						changePlayerState(node, PlayerState.LAND);
					}
					else if(node.playerState.state == PlayerState.FALL || node.playerState.state == PlayerState.DEPLOY_CHUTE)
					{
						CharUtils.setAnim(node.entity, Dizzy);
						changePlayerState(node, PlayerState.CRASH);
					}
				}
			}
		}
				
		private function updateChute(node:SkydiveNode, label:String):void
		{
			var parachute:Parachute = node.parachute;
			var timeline:Timeline = parachute.entity.get(Timeline);

			if(label == "remove")
			{
				super.group.removeEntity(parachute.entity);
			}
			else if(timeline)
			{
				timeline.gotoAndPlay(label);
			}
		}
		
		private function changePlayerState(node:SkydiveNode, newState:String):void
		{
			node.playerState.requestStateChange(newState, int(node.id.id));
		}
	}
}