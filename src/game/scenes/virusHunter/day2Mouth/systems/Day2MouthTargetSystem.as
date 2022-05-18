package game.scenes.virusHunter.day2Mouth.systems
{
	import com.greensock.easing.Quad;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.SceneWeaponTarget;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class Day2MouthTargetSystem extends GameSystem
	{
		private var creator:EnemyCreator;
		private var events:VirusHunterEvents;
		
		public function Day2MouthTargetSystem(creator:EnemyCreator, events:VirusHunterEvents)
		{
			super(SceneWeaponTargetNode, updateNode);
			
			this.creator = creator;
			this.events = events;
		}
		
		private function updateNode(node:SceneWeaponTargetNode, time:Number):void
		{
			if(node.collider.isHit && !node.damageTarget.isTriggered)
			{
				const id:String = removeTarget(node.id.id);
				var color:Entity = this.group.getEntityById(id);
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					node.damageTarget.isTriggered = true;
					
					var tween:Tween = new Tween();
					var object:Object;
					
					if(id.indexOf("tentacle") > -1)
					{
						this.group.shellApi.completeEvent(this.events.WORM_CLEARED_ + id.charAt(8));
						
						node.entity.add(tween);
						object = { alpha:0, onComplete:this.group.removeEntity, onCompleteParams:[node.entity] };
						tween.to(node.entity.get(Display), 1, object);
						
						this.handleWormCameraPan(uint(id.charAt(8)));
					}
					else if(id.indexOf("cut") > -1)
					{
						this.group.shellApi.completeEvent(this.events.DOG_CUT_CURED_ + id.charAt(3));
						this.group.removeEntity(color);
						node.entity.remove(EnemySpawn);
						node.entity.remove(SceneWeaponTarget);
						//this.group.removeEntity(node.entity);
						
						var cut:Entity = this.group.getEntityById("cut" + id.charAt(3) + "Art");
						cut.get(Timeline).gotoAndPlay("start");
						cut.get(Audio).play(SoundManager.EFFECTS_PATH + "squish_07.mp3");
					}
				}
				else
				{
					if(id.indexOf("cut") > -1)
					{
						var cut2:Entity = this.group.getEntityById("cut" + id.charAt(3) + "Art");
						cut2.get(Audio).play(SoundManager.EFFECTS_PATH + "squish_08.mp3");
					}
					else if(id.indexOf("tentacle") > -1 && node.collider._colliderId != "player")
					{
						node.entity.get(Audio).play(SoundManager.EFFECTS_PATH + "tendrils_hit_0" + Utils.randInRange(1, 4) + ".mp3", false, SoundModifier.EFFECTS);
					}
				}
			}
		}
		
		private function handleWormCameraPan(i:uint):void
		{
			SceneUtil.lockInput(this.group);
			
			var camera:CameraSystem = this.group.getSystem(CameraSystem) as CameraSystem;
			camera.target = new Spatial(4260, 1800);
			
			var worm:Entity = this.group.getEntityById("worm" + i);
			
			var spatial:Spatial = worm.get(Spatial);
			var tween:Tween = worm.get(Tween);
			var sleep:Sleep = worm.get(Sleep);
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			
			var rotation:Number = spatial.rotation + 20;
			var x:Number = spatial.x + 1000;
			
			var object:Object = { rotation:rotation, x:x, ease:Quad.easeInOut, onComplete:handleWormMoved, onCompleteParams:[camera, worm] };
			tween.to(spatial, 5, object);
		}
		
		private function handleWormMoved(camera:CameraSystem, worm:Entity):void
		{
			camera.target = this.group.shellApi.player.get(Spatial);
			SceneUtil.lockInput(this.group, false);
			
			var spatial:Spatial = worm.get(Spatial);
			var radians:Number = GeomUtils.degreeToRadian(spatial.rotation);
			var x:Number = Math.cos(radians) * 400 + spatial.x;
			var y:Number = Math.sin(radians) * 400 + spatial.y;
			
			creator.createRandomPickup(x, y, false);
			creator.createRandomPickup(x, y, false);
			
			var id:String = Id(worm.get(Id)).id;
			this.group.removeEntity(this.group.getEntityById(id + "Color"));
			this.group.removeEntity(worm);
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SceneWeaponTargetNode);
			super.removeFromEngine(systemManager);
		}
		
		private function removeTarget(id:String):String
		{
			var index:Number = id.indexOf("Target");
			
			return(id.slice(0, index));
		}
	}
}