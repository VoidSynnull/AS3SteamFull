package game.scenes.virusHunter.day2Intestine.systems
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.hit.Radial;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Intestine.components.NerveMove;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	import game.util.Utils;
	
	public class Day2IntestineTargetSystem extends GameSystem
	{
		private var creator:EnemyCreator;
		private var events:VirusHunterEvents;
		
		public function Day2IntestineTargetSystem(creator:EnemyCreator, events:VirusHunterEvents)
		{
			super(SceneWeaponTargetNode, updateNode);
			this.creator = creator;
			this.events = events;
		}
		
		private function updateNode(node:SceneWeaponTargetNode, time:Number):void
		{
			if(node.collider.isHit && !node.damageTarget.isTriggered)
			{
				node.collider.isHit = false;
				var id:String = removeTarget(node.id.id);
				
				if(id.indexOf("tentacle") > -1 && node.collider._colliderId != "player")
				{
					var audio:Audio = node.entity.get(Audio);
					audio.play(SoundManager.EFFECTS_PATH + "tendrils_hit_0" + Utils.randInRange(1, 4) + ".mp3", false, SoundModifier.EFFECTS);
				}
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					var tween:Tween = new Tween();
					
					if(id.indexOf("tentacle") > -1)
					{
						node.damageTarget.isTriggered = true;
						
						this.group.shellApi.completeEvent(this.events.WORM_CLEARED_ + id.charAt(8));
						
						if(!this.group.shellApi.checkEvent(this.events.RETRACT_WORMS))
							this.group.shellApi.completeEvent(this.events.RETRACT_WORMS);
						
						var radians:Number = GeomUtils.degreeToRadian(node.spatial.rotation);
						var x:Number = Math.cos(radians) * 10 + node.spatial.x;
						var y:Number = Math.sin(radians) * 10 + node.spatial.y;
						
						creator.createRandomPickup(x, y, false);
						creator.createRandomPickup(x, y, false);
						
						node.entity.add(tween);
						var object:Object = { alpha:0, onComplete:this.group.removeEntity, onCompleteParams:[node.entity] };
						tween.to(node.entity.get(Display), 1, object);
					}
					else if(id.indexOf("nerve") > -1)
					{
						trace("Nerve");
						
						node.damageTarget.damage = 0;
						var nerve:Entity = this.group.getEntityById(id);
						
						var nerveMove:NerveMove = nerve.get(NerveMove);
						nerveMove.state = NerveMove.SHOCK_STATE;
						nerveMove.elapsedTime = 0;
						nerveMove.waitTime = Utils.randNumInRange(1, 2);
						
						var sound:String = "contract_expand_muscle_0" + Utils.randInRange(1, 2) + ".mp3";
						Audio(nerve.get(Audio)).play(SoundManager.EFFECTS_PATH + sound, false);
						
						node.entity.add(tween);
						
						const nerveNumber:uint = uint(id.charAt(5));
						switch(nerveNumber)
						{
							case 1: handleNerve(node, [1, 3], 	["y", "x"], tween); break;
							case 2: handleNerve(node, [2], 		["x"], 		tween); break;
							case 3: handleNerve(node, [2, 4], 	["x", "y"], tween); break;
							case 4: handleNerve(node, [6], 		["y"], 		tween); break;
							case 5: handleNerve(node, [3, 5], 	["x", "y"], tween); break;
							case 6: handleNerve(node, [2], 		["x"], 		tween); break;
							case 7: handleNerve(node, [3], 		["x"], 		tween); break;
						}
					}
				}
			}
		}
		
		private function handleNerve(node:SceneWeaponTargetNode, groups:Array, axes:Array, tween:Tween):void
		{
			for(var i:uint = 0; i < groups.length; i++)
			{
				var color:Entity = this.group.getEntityById("muscleGroup" + groups[i]);
				if(color.get(Radial))
				{
					color.remove(Radial);
					moveMuscle(node, groups[i], axes[i], tween, 0.5);
				}
				else
				{
					var radial:Radial = new Radial();
					radial.rebound = -2;
					color.add(radial);
					moveMuscle(node, groups[i], axes[i], tween, 1);
				}
			}
		}
		
		private function moveMuscle(node:SceneWeaponTargetNode, group:uint, axis:String, tween:Tween, size:Number):void
		{
			var clip:MovieClip;
			if(axis == "x")
			{
				tween.to(node.display.container["muscle" + group + "A"], 1, {scaleX:size});
				tween.to(node.display.container["muscle" + group + "B"], 1, {scaleX:size});
			}
			else if(axis == "y")
			{
				tween.to(node.display.container["muscle" + group + "A"], 1, {scaleY:size});
				tween.to(node.display.container["muscle" + group + "B"], 1, {scaleY:size});
			}
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