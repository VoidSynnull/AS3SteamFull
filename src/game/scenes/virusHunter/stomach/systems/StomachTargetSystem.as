package game.scenes.virusHunter.stomach.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.components.hit.Radial;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.scenes.virusHunter.stomach.Stomach;
	import game.systems.GameSystem;
	import game.util.SceneUtil;
	
	public class StomachTargetSystem extends GameSystem
	{
		private var scene:Stomach;
		private var events:VirusHunterEvents;
		
		public function StomachTargetSystem(scene:Scene, events:VirusHunterEvents)
		{
			super(SceneWeaponTargetNode, updateNode);
			
			this.scene = scene as Stomach;
			this.events = events;
		}
		
		private function updateNode(node:SceneWeaponTargetNode, time:Number):void
		{
			if(node.collider.isHit && !node.damageTarget.isTriggered)
			{
				var id:String = removeTarget(node.id.id);
				var target:Entity = node.entity;
				var color:Entity = this.scene.getEntityById(id);
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					node.damageTarget.isTriggered = true;
					
					if(id.indexOf("ulcer") > -1)
					{
						this.scene.shellApi.completeEvent(this.events.ULCER_CURED);
						color.remove(Radial);
						this.scene.removeEntity(target);
						
						var ulcer2:Entity = this.group.getEntityById("ulcerArt");
						ulcer2.get(Timeline).gotoAndPlay("start");
						ulcer2.get(Audio).play(SoundManager.EFFECTS_PATH + "squish_07.mp3");
						
						SceneUtil.addTimedEvent(this.group, new TimedEvent(2, -1, handleUlcer));
					}
				}
				else
				{
					if(id.indexOf("ulcer") > -1)
					{
						var ulcer:Entity = this.group.getEntityById("ulcerArt");
						ulcer.get(Audio).play(SoundManager.EFFECTS_PATH + "squish_08.mp3");
					}
				}
			}
		}
		
		private function handleUlcer():void
		{
			this.scene.playMessage("stomach_resolved", false);
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