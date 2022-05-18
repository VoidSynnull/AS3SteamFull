package game.scenes.virusHunter.day2Stomach.systems
{
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.motion.Threshold;
	import game.components.hit.Radial;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class Day2StomachTargetSystem extends GameSystem
	{
		private var creator:EnemyCreator;
		private var events:VirusHunterEvents;
		private var numChunksFallen:uint = 0;
		
		public function Day2StomachTargetSystem(creator:EnemyCreator, events:VirusHunterEvents)
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
				var target:Entity = node.entity;
				var color:Entity = this.group.getEntityById(id);
				var audio:Audio = this.group.shellApi.player.get(Audio);
				
				node.collider.isHit = false;
				
				if(id.indexOf("treat") > -1)
					audio.play(SoundManager.EFFECTS_PATH + "dirt_break_0" + Utils.randInRange(1, 5) + ".mp3", false, SoundModifier.EFFECTS);
				else if(id.indexOf("tentacle") > -1 && node.collider._colliderId != "player")
					audio.play(SoundManager.EFFECTS_PATH + "tendrils_hit_0" + Utils.randInRange(1, 4) + ".mp3", false, SoundModifier.EFFECTS);
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					node.damageTarget.isTriggered = true;
					var tween:Tween = new Tween();
					var object:Object;
					
					if(id.indexOf("tentacle") > -1)
					{
						this.group.shellApi.completeEvent(this.events.WORM_CLEARED_ + id.substr(8));
						
						if(!this.group.shellApi.checkEvent(this.events.RETRACT_WORMS))
							this.group.shellApi.completeEvent(this.events.RETRACT_WORMS);
						
						node.entity.add(tween);
						object = { alpha:0, onComplete:this.group.removeEntity, onCompleteParams:[node.entity] };
						tween.to(node.entity.get(Display), 1, object);
						
						var radians:Number = GeomUtils.degreeToRadian(node.spatial.rotation);
						var x:Number = Math.cos(radians) * 300 + node.spatial.x;
						var y:Number = Math.sin(radians) * 300 + node.spatial.y;
						
						creator.createRandomPickup(x, y, false);
						creator.createRandomPickup(x, y, false);
					}
					else if(id.indexOf("fat") > -1 || id.indexOf("treat") > -1)
					{
						this.group.removeEntity(target);
						
						var entity:Entity;
						var motion:Motion;
						
						if(id.indexOf("fat") > -1)
						{
							this.group.shellApi.completeEvent(this.events.STOMACH_FAT_CLEARED_ + id.charAt(3));
							
							var animation:Entity = this.group.getEntityById(id + "Art");
							
							var timeline:Timeline = animation.get(Timeline);
							timeline.gotoAndPlay("start");
							timeline.handleLabel("break", Command.create(handleFat, id, node, color));
						}
						else if(id.indexOf("treat") > -1)
						{
							color.remove(Radial);
							
							var num:Number = Number(id.charAt(5));
							this.group.shellApi.completeEvent(this.events.DOG_TREAT_CLEARED_ + num);
						
							var sprite:Sprite = node.display.container[id + "Art"];
							
							setupChunks(sprite.x, sprite.y);
							node.display.container.removeChild(sprite);
							
							if(num % 2 == 0 && !this.group.shellApi.checkEvent((this.events.DOG_TREAT_CLEARED_ + (num-1))))
							{
								this.group.shellApi.completeEvent(this.events.DOG_TREAT_CLEARED_ + (num-1));
								
								sprite = node.display.container["treat" + (num-1) + "Art"];
								
								var treatColor:Entity = this.group.getEntityById("treat" + (num-1));
								if(treatColor) this.group.removeEntity(treatColor);
								
								var treatTarget:Entity = this.group.getEntityById("treat" + (num-1) + "Target");
								if(treatTarget) this.group.removeEntity(treatTarget);
								
								var value:uint;
								if(num == 2) value = 900;
								else if(num == 4) value = 2400;
								else if(num == 6) value = 2030;
								
								entity = handleReaction(sprite, value, handleTreat, "dirt_break_0" + Utils.randInRange(1, 5) + ".mp3");
								motion = entity.get(Motion);
								motion.rotationVelocity = Utils.randNumInRange(-50, 50);
							}
						}
					}
				}
				else
				{
					if(id.indexOf("fat") > -1)
					{
						if(!TweenMax.isTweening(node.display.container[id + "Art"]))
						{
							this.group.shellApi.triggerEvent("fatBounce");
							DisplayUtils.customBounceTransition(TweenMax, node.display.container[id + "Art"], 1.5, .75);
						}
					}
				}
			}
		}
		
		private function handleFat(id:String, node:SceneWeaponTargetNode, color:Entity):void
		{
			color.remove(Radial);
			
			var container:DisplayObjectContainer = Display(this.group.shellApi.player.get(Display)).container;
			var clip:MovieClip;
			var entity:Entity;
			var motion:Motion;
			
			if(id == "fat3")
			{
				for(var i:uint = 1; i <= 4; i++)
				{
					
					clip = container["chunk" + i];
					entity = handleReaction(clip, 2000, handleChunk, "fs_mud_0" + Utils.randInRange(1, 4) + ".mp3");
					motion = entity.get(Motion);
					motion.velocity.y = Utils.randNumInRange(0, 100);
					motion.rotationVelocity = Utils.randNumInRange(-200, 200);
				}
			}
			else if(id == "fat4" || id == "fat5")
			{
				if(this.group.getEntityById("fat4").get(Radial) == null && this.group.getEntityById("fat5").get(Radial) == null)
				{
					clip = container["bone"];
					entity = handleReaction(clip, 1880, handleBone, "fs_mud_0" + Utils.randInRange(1, 4) + ".mp3");
				}
			}
		}
		
		private function handleReaction(clip:DisplayObjectContainer, value:Number, handler:Function, sound:String = ""):Entity
		{
			var entity:Entity = EntityUtils.createMovingEntity(this.group, clip);
			
			var motion:Motion = new Motion();
			motion.acceleration.y = 600;
			entity.add(motion);
			
			if(sound != "")
			{	
				entity.add(new Audio());
				entity.add(new AudioRange(600, 0.01, 1));
			}
			
			var threshold:Threshold = new Threshold("y", ">=");
			threshold.threshold = value;
			threshold.entered.addOnce(Command.create(handler, entity, sound));
			entity.add(threshold);
			
			return entity;
		}
		
		private function handleTreat(treat:Entity, sound:String):void
		{
			var audio:Audio = this.group.shellApi.player.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "dirt_break_0" + Utils.randInRange(1, 5) + ".mp3");
			
			setupChunks(treat.get(Spatial).x, treat.get(Spatial).y);
			
			this.group.removeEntity(treat);
		}
		
		private function handleChunk(chunk:Entity, sound:String):void
		{
			chunk.remove(Threshold);
			chunk.remove(Motion);
			
			if(sound != null)
				Audio(chunk.get(Audio)).play(SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION);
			
			this.numChunksFallen++;
			if(this.numChunksFallen >= 4)
			{
				var tween:Tween = new Tween();
				var tentacle:Entity = this.group.getEntityById("tentacle9Target");
				if(tentacle)
				{
					tentacle.add(tween);
					var object:Object = { alpha:0, onComplete:this.group.removeEntity, onCompleteParams:[tentacle] };
					tween.to(tentacle.get(Display), 1, object);
					
					if(!this.group.shellApi.checkEvent(this.events.RETRACT_WORMS))
						this.group.shellApi.completeEvent(this.events.RETRACT_WORMS);
				
					this.group.shellApi.completeEvent(this.events.WORM_CLEARED_ + 9);
				}
			}
		}
		
		private function handleBone(bone:Entity, sound:String):void
		{
			bone.remove(Threshold);
			var motion:Motion = bone.get(Motion);
			motion.velocity = new Point();
			motion.acceleration = new Point();
			motion.previousAcceleration = new Point();
			
			if(sound != null)
				Audio(bone.get(Audio)).play(SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION);
			
			var tween:Tween = new Tween();
			tween.to(bone.get(Spatial), .75, { x : 2000, y : 2000, rotation : -60 });
			bone.add(tween);
			
			tween = new Tween();
			var tentacle:Entity = this.group.getEntityById("tentacle10Target");
			if(tentacle)
			{
				tentacle.add(tween);
				var object:Object = { alpha:0, onComplete:this.group.removeEntity, onCompleteParams:[tentacle] };
				tween.to(tentacle.get(Display), 1, object);
				
				if(!this.group.shellApi.checkEvent(this.events.RETRACT_WORMS))
					this.group.shellApi.completeEvent(this.events.RETRACT_WORMS);
			
				this.group.shellApi.completeEvent(this.events.WORM_CLEARED_ + 10);
			}
		}
		
		private function setupChunks(x:Number, y:Number):void
		{
			for(var j:uint = 1; j <= 3; j++)
			{
				var chunk:Entity = this.group.getEntityById("chunk" + j);
				
				var spatial:Spatial = chunk.get(Spatial);
				spatial.x = x + Utils.randNumInRange(-125, 125);
				spatial.y = y + Utils.randNumInRange(-125, 125);
				
				var motion:Motion = chunk.get(Motion);
				motion.velocity.x = Utils.randNumInRange(-175, 175);
				motion.velocity.y = Utils.randNumInRange(-50, -100);
				motion.rotationVelocity = Utils.randNumInRange(-400, 400);
				motion.pause = false;
				
				Display(chunk.get(Display)).alpha = 1;
				
				SceneUtil.addTimedEvent(this.group, new TimedEvent(0, 20, Command.create(handleChunkPiece, chunk)));
			}
		}
		
		private function handleChunkPiece(chunk:Entity):void
		{
			var display:Display = chunk.get(Display);
			display.alpha -= 0.05;
			if(display.alpha <= 0) chunk.get(Motion).pause = true;
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