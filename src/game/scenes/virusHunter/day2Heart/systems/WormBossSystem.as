package game.scenes.virusHunter.day2Heart.systems 
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.systems.CameraSystem;
	import engine.systems.CameraZoomSystem;
	
	import game.components.motion.FollowTarget;
	import game.components.entity.Sleep;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.day2Heart.Day2Heart;
	import game.scenes.virusHunter.day2Heart.components.WormBoss;
	import game.scenes.virusHunter.day2Heart.nodes.WormBossNode;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	import org.as3commons.collections.framework.IListIterator;

	public class WormBossSystem extends ListIteratingSystem
	{
		private var scene:Day2Heart;
		private var events:VirusHunterEvents;
		
		public function WormBossSystem(scene:Day2Heart, events:VirusHunterEvents) 
		{
			super(WormBossNode, updateNode);
			
			this.scene = scene;
			this.events = events;
		}
		
		private function updateNode(node:WormBossNode, time:Number ):void
		{
			if(node.sleep.sleeping) return;
			
			var iterator:IListIterator;
			
			trace(node.boss.state);
			switch(node.boss.state)
			{
				case WormBoss.IDLE_STATE:
					//Placeholder
				break;
				
				case WormBoss.SETUP_STATE:
					setupCamera(true, node.entity.get(Spatial));
					node.boss.state = WormBoss.VIEW_STATE;
					break;
				
				case WormBoss.VIEW_STATE:
					if(updateState(node, time, 5, WormBoss.IDLE_STATE))
						setupCamera(false, this.group.shellApi.player.get(Spatial));
				break;
				
				case WormBoss.ANGRY_STATE:
					if(updateState(node, time, 5, WormBoss.MOVE_STATE))
					{
						var follow:FollowTarget = node.entity.get(FollowTarget);
						follow.rate += 0.0005;
					}
				break;
				
				case WormBoss.MOVE_STATE:
					trace("Masses:" + node.boss.numMasses);
					trace("Tentacles:" + node.boss.numTentacles);
					if(node.boss.numMasses <= 0 && node.boss.numTentacles <= 0)
					{
						SceneUtil.addTimedEvent(this.scene, new TimedEvent(5, -1, fadeToWhite));
						this.scene.shipGroup.createWhiteBloodCellSwarm(node.spatial);
						
						node.boss.state = WormBoss.DEATH_STATE;
					}
				break;
				
				case WormBoss.DEATH_STATE:
					//Placeholder
				break;
			}
		}
		
		private function setupCamera(lock:Boolean, target:Spatial):void
		{
			SceneUtil.lockInput(this.group, lock);
			CharUtils.lockControls(this.group.shellApi.player, lock, lock);
			
			var camera:CameraSystem = this.group.getSystem(CameraSystem) as CameraSystem;
			camera.target = target;
			
			var zoom:CameraZoomSystem = this.group.getSystem(CameraZoomSystem) as CameraZoomSystem;
			
			if(lock)
			{
				MotionUtils.zeroMotion(this.group.shellApi.player);
				camera.rate = 0.02;
				zoom.scaleRate = 0.05;
				zoom.scaleTarget = 1.1;
			}
			else
			{
				camera.rate = 0.2;
				zoom.scaleTarget = 0.5;
			}
		}
		
		private function updateState(node:WormBossNode, time:Number, waitTime:Number, nextState:String):Boolean
		{
			node.boss.elapsedTime += time;
			if(node.boss.elapsedTime >= waitTime)
			{
				node.boss.elapsedTime = 0;
				node.boss.state = nextState;
				return true;
			}
			return false;
		}
		
		private function fadeToWhite():void
		{
			var explosion:Sprite = this.scene.explosion;
			var tween:Tween = new Tween();
			tween.to(explosion, 0.3, { alpha:1, ease:Quad.easeOut, onComplete:fadeFromWhite, onCompleteParams:[tween, explosion] });
			this.group.shellApi.player.add(tween);
		}
		
		private function fadeFromWhite(tween:Tween, explosion:Sprite):void
		{
			this.scene.shipGroup.whiteBloodCellExit();
			
			this.group.shellApi.completeEvent(this.events.WORM_BOSS_DEFEATED);
			this.group.shellApi.triggerEvent(this.events.BOSS_BATTLE_ENDED);
			
			this.group.removeEntity(this.group.getEntityById("boss"));
			this.group.getEntityById("doorLungs").get(Sleep).sleeping = false;
			this.group.getEntityById("doorMouth").get(Sleep).sleeping = false;
			tween.to(explosion, 1, { alpha:0, ease:Quad.easeIn });
			
			SceneUtil.addTimedEvent(this.group, new TimedEvent(1, -1, handleValve));
		}
		
		private function handleValve():void
		{
			this.scene.playMessage("heartworm_contained", false, "virus_attack");
			
			var tween:Tween = new Tween();
			
			this.group.removeEntity(this.group.getEntityById("valve"));
			
			var container:DisplayObjectContainer = Display(this.group.shellApi.player.get(Display)).container;
			
			var sprite:Sprite;
			var object:Object;
			
			sprite = container["valve1"];
			object = {rotation:sprite.rotation + 70};
			tween.to(sprite, 1, object);
			
			sprite = container["valve2"];
			object = {rotation:sprite.rotation - 70};
			tween.to(sprite, 1, object);
			
			this.group.shellApi.player.add(tween);
		}
	}
}