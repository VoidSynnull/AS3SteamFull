package game.scenes.virusHunter.brain.systems
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.components.hit.Radial;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	
	public class BrainSceneTargetSystem extends ListIteratingSystem
	{
		public function BrainSceneTargetSystem($container:DisplayObjectContainer, $group:Group)
		{
			_sceneGroup = $group;
			super(SceneWeaponTargetNode, updateNode);
		}
		
		private function updateNode(node:SceneWeaponTargetNode, time:Number):void
		{
			if(node.collider.isHit && !node.damageTarget.isTriggered)
			{
				var hitId:String = removeTarget(node.id.id);
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					node.damageTarget.isTriggered = true;
					
					var entity:Entity = _sceneGroup.getEntityById(hitId);
					var artEntity:Entity = _sceneGroup.getEntityById(hitId + "Art");
					var timeline:Timeline = artEntity.get(Timeline);
					timeline.gotoAndPlay("start");
					// remove hit entity
					
					if(hitId == "muscle")
					{
						entity.remove(Radial);
						_sceneGroup.shellApi.triggerEvent("shockOpen");
						
						var audio:Audio = entity.get( Audio );
						if( !audio )
						{
							audio = new Audio();
							entity.add( audio );
						}
						
						audio.play( SoundManager.EFFECTS_PATH + STRETCH_NERVE, false );
					}
					else if(hitId == "bloodFlow")
					{
						_sceneGroup.shellApi.triggerEvent("healWound");
					}
					
					_sceneGroup.removeEntity(entity);
					_sceneGroup.removeEntity(node.entity);
				}
				else
				{
					if(hitId == "bloodFlow")
					{
						_sceneGroup.shellApi.triggerEvent("hitWound");
					}
				}
			}
		}
		
		private function removeTarget(id:String):String
		{
			var index:Number = id.indexOf("Target");
			
			return(id.slice(0, index));
		}
		
		private var _sceneGroup:Group;
		private static const STRETCH_NERVE:String = "rubber_stretch_14.mp3";
	}
}