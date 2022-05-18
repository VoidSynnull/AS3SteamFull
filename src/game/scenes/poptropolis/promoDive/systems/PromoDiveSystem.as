package game.scenes.poptropolis.promoDive.systems 
{
	import flash.display.DisplayObject;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	
	import game.components.entity.collider.HazardCollider;
	import game.scenes.poptropolis.promoDive.PromoDive;
	import game.scenes.poptropolis.promoDive.nodes.FishNode;
	import game.scenes.poptropolis.promoDive.nodes.JellyNode;
	import game.scenes.poptropolis.promoDive.nodes.SharkNode;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	
	public class PromoDiveSystem extends System
	{
		private var _fish:NodeList;
		private var fish:FishNode;
		private var _jellies:NodeList;
		private var jelly:JellyNode;
		private var _sharks:NodeList;
		private var shark:SharkNode;
		private var mX:Number;
		private var mY:Number;
		private var mouseContainer:DisplayObject;
		private var playerSpatial:Spatial;
		
		private var _scene:Scene;
			
		public function PromoDiveSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_scene = PromoDive(super.group);
			_fish = systemManager.getNodeList( FishNode );
			fish = _fish.head;
			_jellies = systemManager.getNodeList( JellyNode );
			jelly = _jellies.head;
			_sharks = systemManager.getNodeList( SharkNode );
			shark = _sharks.head;
			playerSpatial = PromoDive(super.group).player.get(Spatial);
			mouseContainer = PromoDive(super.group).player.get(Display).container;
		}
		
		override public function update( time:Number ):void
		{
			var collider:HazardCollider;
			
			for(fish = _fish.head; fish; fish = fish.next){
				if(fish.fish.facingRight){
					if(fish.spatial.x < fish.fish.right){
						fish.spatial.x += fish.fish.speed;
					}else{
						fish.fish.facingRight = false;
						fish.spatial.scaleX = -1;
					}
				}else{
					if(fish.spatial.x > fish.fish.left){
						fish.spatial.x -= fish.fish.speed;
					}else{
						fish.fish.facingRight = true;
						fish.spatial.scaleX = 1;
					}
				}
				
				//Fish Hit Sound!
				if(fish.hit.collider)
				{
					collider = fish.hit.collider.get(HazardCollider);
					if(collider.isHit)
						AudioUtils.play(this.group, SoundManager.EFFECTS_PATH + "fish_hit_01.mp3");
				}
			}
			
			for(jelly = _jellies.head; jelly; jelly = jelly.next){
				if(jelly.jelly.goingUp){
					if(jelly.spatial.y > jelly.jelly.top){
						jelly.spatial.y -= jelly.jelly.speed;
					}else{
						jelly.jelly.goingUp = false;
					}
				}else{
					if(jelly.spatial.y < jelly.jelly.bottom){
						jelly.spatial.y += jelly.jelly.speed;
					}else{
						jelly.jelly.goingUp = true;
					}
				}
				
				//Jelly Hit Sound!
				if(jelly.hit.collider)
				{
					collider = jelly.hit.collider.get(HazardCollider);
					if(collider.isHit)
						AudioUtils.play(this.group, SoundManager.EFFECTS_PATH + "fish_hit_01.mp3");
				}
			}
			
			for(shark = _sharks.head; shark; shark = shark.next){
				if(Math.abs(shark.spatial.y - playerSpatial.y) < 100){
					if(!shark.shark.attacking){
						PromoDive(super.group).playSharkAttack();
						shark.shark.attacking = true;
						if(shark.spatial.x > playerSpatial.x){
							shark.shark.facingRight = false;
							shark.spatial.scaleX = 1;
						}else{
							shark.shark.facingRight = true;
							shark.spatial.scaleX = -1;
						}
						shark.timeline.gotoAndPlay("bite");
						shark.display.displayObject["head"].gotoAndPlay("bite");
					}
				}
				if(shark.shark.facingRight){
					if(shark.spatial.x < shark.shark.right){
						if(shark.shark.attacking){
							shark.spatial.x += shark.shark.speed*2;
						}else{
							shark.spatial.x += shark.shark.speed;
						}
					}else{
						shark.shark.facingRight = false;
						shark.spatial.scaleX = 1;
						if(shark.shark.attacking){
							shark.shark.attacking = false;
							shark.display.displayObject["head"].gotoAndStop(1);
						}
					}
				}else{
					if(shark.spatial.x > shark.shark.left){
						if(shark.shark.attacking){
							shark.spatial.x -= shark.shark.speed*2;
						}else{
							shark.spatial.x -= shark.shark.speed;
						}
					}else{
						shark.shark.facingRight = true;
						shark.spatial.scaleX = -1;
						if(shark.shark.attacking){
							shark.shark.attacking = false;
							shark.display.displayObject["head"].gotoAndStop(1);
						}
					}
				}
				if(shark.display.displayObject["head"].currentFrameLabel == 'bite'){
					trace("biteENd");
					PromoDive(super.group).makeBiteSound();
				}
				//Shark Hit Sound!
				if(shark.hit.collider)
				{
					collider = shark.hit.collider.get(HazardCollider);
					if(collider.isHit)
						AudioUtils.play(this.group, SoundManager.EFFECTS_PATH + "fish_hit_01.mp3");
				}
				if(PromoDive(super.group).playerStop != 0){
					playerSpatial.x = PromoDive(super.group).playerStop;
				}
			}
		}

		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( FishNode );
			_fish = null;
		}
	}
}




