package game.systems.hit
{
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import game.components.hit.Platform;
	import game.creators.scene.HitCreator;
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.HitAudioData;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.MoverHitData;
	import game.nodes.entity.collider.BoundsCollisionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	public class BaseGroundHitSystem extends GameSystem
	{
		public function BaseGroundHitSystem()
		{
			super(BoundsCollisionNode, updateNode, null, null);
			super._defaultPriority = SystemPriorities.checkCollisions;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function updateNode(node:BoundsCollisionNode, time:Number):void
		{			
			if (!node.collider.isHit && node.bounds.bottom)
			{				
				node.collider.isHit = true;
				node.collider.baseGround = true;
				node.currentHit.hit = _hitEntity;
				
				if(_stickToPlatforms || node.motion.velocity.y > 0)
				{
					if(node.motion.acceleration.y > 0)
					{
						EntityUtils.playAudioAction(node.hitAudio, _hitAudioData);
					}
					
					node.motion.acceleration.y = 0;
					node.motion.velocity.y = 0;
				}
			}
		}
		
		override public function removeFromEngine(gameSystems:Engine) : void
		{
			gameSystems.releaseNodeList(BoundsCollisionNode);
			super.removeFromEngine(gameSystems);
		}
		
		public function setBaseGroundHitData(data:HitData, audioData:Dictionary):void 
		{
			if(_hitEntity == null)
			{
				_hitEntity = new Entity();
			}
			
			if(data.components["platform"])
			{				
				var platformHit:Platform = new Platform();
				platformHit.friction = MoverHitData(data.components["platform"]).friction;
				_stickToPlatforms = MoverHitData(data.components["platform"]).stickToPlatforms;
				_hitEntity.add(platformHit);
			}
			
			_hitEntity.add(data);
			
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.addAudioToHit(_hitEntity, audioData, null, super.group.shellApi);
			_hitAudioData = _hitEntity.get(HitAudioData);
		}
		
		private var _hitEntity:Entity;
		private var _hitAudioData:HitAudioData;
		private var _stickToPlatforms:Boolean;
	}
}
