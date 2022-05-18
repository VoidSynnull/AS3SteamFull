package game.scenes.virusHunter.intestine.systems
{
	import com.greensock.TweenMax;
	
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.hit.Radial;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.intestine.Intestine;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class IntestineTargetSystem extends GameSystem
	{
		private var scene:Intestine;
		private var events:VirusHunterEvents;
		
		public function IntestineTargetSystem(scene:Intestine, events:VirusHunterEvents)
		{
			super(SceneWeaponTargetNode, updateNode);
			
			this.scene = scene;
			this.events = events;
		}
		
		private function updateNode(node:SceneWeaponTargetNode, time:Number):void
		{
			if(node.collider.isHit && !node.damageTarget.isTriggered)
			{
				var id:String = removeTarget(node.id.id);
				var target:Entity = node.entity;
				var color:Entity = this.scene.getEntityById(id);
				var tween:Tween;
				
				if(id.indexOf("blockage") > -1)
				{
					this.scene.shellApi.triggerEvent(this.events.BLOCKAGE_SHOT_ + Utils.randInRange(1, 3));
					
					var frame:uint = Math.ceil( 4 * (node.damageTarget.damage / node.damageTarget.maxDamage) );
					var blockage:MovieClip = node.display.container[id + "Clip"];
					blockage.gotoAndStop(frame);
					
					for(var i:uint = 0; i <= 1; i++)
					{
						var num:uint = this.scene.currentChunk + (i * 10);
						var chunk:Entity = this.scene.getEntityById("chunk" + num);
						
						Timeline(chunk.get(Timeline)).gotoAndStop( Utils.randNumInRange(0, 7) );
						var display:Display = chunk.get(Display);
						display.alpha = 1;
						
						var spatial:Spatial = chunk.get(Spatial);
						spatial.x = blockage.x + Utils.randNumInRange(-125, 125);
						spatial.y = blockage.y + Utils.randNumInRange(-125, 125);
						spatial.scale = Utils.randNumInRange(1, 2.5);
						
						var motion:Motion = chunk.get(Motion);
						motion.velocity.x = Utils.randNumInRange(-175, 175);
						motion.velocity.y = Utils.randNumInRange(-300, -100);
						motion.rotationVelocity = Utils.randNumInRange(-400, 400);
						motion.pause = false;
						
						tween = chunk.get(Tween);
						tween.destroy();
						tween.tweens = new Vector.<TweenMax>();
						tween.to(spatial, 2, { scale:0, onComplete:handleChunk, onCompleteParams:[display, spatial, motion] });
					}
					
					if(this.scene.currentChunk >= this.scene.numChunks) this.scene.currentChunk = 1;
					else this.scene.currentChunk++;
				}
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					if(id.indexOf("blockage") > -1)
					{
						this.scene.shellApi.completeEvent(this.events.BLOCKAGE_CLEARED_ + id.charAt(id.length - 1));
						
						tween = new Tween();
						this.group.shellApi.player.add(tween);
						tween.to(node.display.container[id + "Clip"], 2, { alpha:0 });
					}
					else if(id.indexOf("nerve") > -1)
					{
						var clip:MovieClip = node.display.container["coinClip"];
						this.scene.removeEntity(this.scene.getEntityById("coin"));
						SceneUtil.addTimedEvent(this.scene, new TimedEvent(0, 40, Command.create(handleCoin, clip)));
						
						for(var j:uint = 1; j <= 2; j++)
						{
							clip = node.display.container["muscle" + j + "Clip"];
							SceneUtil.addTimedEvent(this.scene, new TimedEvent(0, 8, Command.create(handleMuscle, clip)));
							
							var audio:Audio = this.group.shellApi.player.get(Audio);
							audio.play(SoundManager.EFFECTS_PATH + "contract_expand_muscle_0" + Utils.randInRange(1, 2) + ".mp3");
						}
						this.scene.shellApi.completeEvent(this.events.CRAMP_CURED);
						SceneUtil.addTimedEvent(this.group, new TimedEvent(3, -1, handleCramp));
					}
					
					if(id.indexOf("blockage") > -1 || id.indexOf("nerve") > -1)
					{
						color.remove(Radial);
						node.damageTarget.isTriggered = true;
						this.scene.removeEntity(target);
					}
				}
			}
		}
		
		private function handleCramp():void
		{
			this.scene.playMessage("intestine_resolved", false);
		}
		
		private function handleBlockage(blockage:Entity):void
		{
			this.group.removeEntity(blockage);
		}
		
		private function handleChunk(display:Display, spatial:Spatial, motion:Motion):void
		{
			display.alpha = 0;
			spatial.scale = 1;
			motion.pause = true;
		}
		
		private function handleMuscle(clip:MovieClip):void
		{
			clip.scaleY -= 0.05;
			clip.scaleX -= 0.025;
		}
		
		private function handleCoin(clip:MovieClip):void
		{
			if(clip.y < 2575) clip.y += 15;
			clip.x -= 20;
			clip.rotation -= 10;
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