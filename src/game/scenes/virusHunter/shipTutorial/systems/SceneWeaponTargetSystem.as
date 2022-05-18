package game.scenes.virusHunter.shipTutorial.systems
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Tween;
	import engine.group.Scene;
	
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Mover;
	import game.components.hit.Radial;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	import game.util.DisplayUtils;
	
	public class SceneWeaponTargetSystem extends GameSystem
	{
		public function SceneWeaponTargetSystem(scene:Scene)
		{
			super(SceneWeaponTargetNode, updateNode);
			_scene = scene;
		}
		
		private function updateNode(node:SceneWeaponTargetNode, time:Number):void
		{
			if(node.collider.isHit && !node.damageTarget.isTriggered)
			{
				var hitId:String = removeTarget(node.id.id);
				var entity:Entity = _scene.getEntityById(hitId);
				var tween:Tween;
				var timeline:Timeline;
				var artEntity:Entity;
				var spawn:EnemySpawn;
				var shockOpen:Boolean = false;
				//trace("node.damageTarget.damage : " + node.damageTarget.damage + "/" + node.damageTarget.maxDamage + " : " + hitId);
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					if(hitId == NERVE || hitId.indexOf(MUSCLE) > -1 || hitId.indexOf(FAT) > -1)
					{
						node.entity.remove(MovieClipHit);
						entity.remove(Radial);
						node.damageTarget.isTriggered = true;
						tween = new Tween();
						node.entity.add(tween);
							
						if(hitId.indexOf(FAT) > -1)
						{
							artEntity = _scene.getEntityById(hitId + "Art");
							timeline = artEntity.get(Timeline);
							timeline.gotoAndPlay("fatOpen");
							removeEntity(node.entity);
							//tween.to(node.display.container[hitId + "Art"], .75, { alpha : 0, onComplete : removeEntity, onCompleteParams : [node.entity] });
						}
						else if(hitId == "muscle1")
						{
							tween.to(node.display.container["muscleArt1"], .75, { scaleX : 1, ease : Sine.easeIn, onComplete : removeEntity, onCompleteParams : [node.entity] });
							tween.to(node.display.container["muscleArt2"], .75, { scaleX : 1, ease : Sine.easeIn });
							shockOpen = true;
						}
						else if(hitId == "muscle2")
						{
							tween.to(node.display.container["muscleArt3"], .75, { scaleX : 1, ease : Sine.easeIn, onComplete : removeEntity, onCompleteParams : [node.entity] });
							shockOpen = true;
						}
						else if(hitId == "nerve")
						{
							tween.to(node.display.container["nerve3"], .75, { rotation : 135, ease : Sine.easeIn, onComplete : removeEntity, onCompleteParams : [node.entity] });
							tween.to(node.display.container["nerve4"], .75, { rotation : 11, ease : Sine.easeIn });
							shockOpen = true;
						}
						
						if(shockOpen)
						{
							_scene.shellApi.triggerEvent("shockOpen");
						}
					}
					else if(hitId.indexOf(BLOOD_FLOW) > -1)
					{
						node.entity.remove(MovieClipHit);
						artEntity = _scene.getEntityById(hitId + "Art");
						timeline = artEntity.get(Timeline);
						timeline.gotoAndPlay("start");
						entity.remove(Mover);
						node.damageTarget.isTriggered = true;
						spawn = node.entity.get(EnemySpawn);
						spawn.max = 0;
						_scene.shellApi.triggerEvent("healWound");
						//removeEntity(node.entity);
						/*
						tween = new Tween();
						node.entity.add(tween);
						tween.to(node.display.container[hitId + "Art"], .75, { alpha : 0, onComplete : removeEntity, onCompleteParams : [node.entity] });
						*/
					}
				}
				else
				{
					if(hitId.indexOf(FAT) > -1)
					{
						tween = node.entity.get(Tween);
						
						if(tween == null)
						{
							tween = new Tween();
							node.entity.add(tween);
						}
						// temp - using tweenMax directly until delay is fixed
						//if(tween.tweens.length == 0)
						if(!TweenMax.isTweening(node.display.container[hitId + "Art"]))
						{
							DisplayUtils.customBounceTransition(TweenMax, node.display.container[hitId + "Art"], 1.5, .75);
							_scene.shellApi.triggerEvent("fatBounce");
							//tween.to(node.display.container.getChildByName(hitId + "Art"), .75, { scaleX : 1, ease : Bounce.easeIn });
						}						
					}
					else if(hitId.indexOf(BLOOD_FLOW) > -1)
					{
						_scene.shellApi.triggerEvent("hitWound");
					}
				}
			}
		}
		
		private function removeEntity(entity:Entity):void
		{
			_scene.removeEntity(entity);
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
		
		public const MUSCLE:String = "muscle";
		public const NERVE:String = "nerve";
		public const BLOOD_FLOW:String = "bloodFlow";
		public const FAT:String = "fat";
		private var _scene:Scene;
	}
}