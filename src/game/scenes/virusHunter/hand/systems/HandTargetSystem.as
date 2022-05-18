package game.scenes.virusHunter.hand.systems
{	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Tween;
	import engine.group.Scene;
	
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Mover;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	
	public class HandTargetSystem extends GameSystem
	{
		public function HandTargetSystem( scene:Scene, events:VirusHunterEvents )
		{
			super( SceneWeaponTargetNode, updateNode );
			_scene = scene;
			_events = events;
		}
		
		private function updateNode( node:SceneWeaponTargetNode, time:Number ):void
		{			
			if( node.collider.isHit && !node.damageTarget.isTriggered )
			{
				var hitId:String = removeTarget( node.id.id );
				var entity:Entity = _scene.getEntityById( hitId );
				var tween:Tween;
				var artEntity:Entity;
				var timeline:Timeline;
				
				if( node.damageTarget.damage >= node.damageTarget.maxDamage )
				{
					node.entity.remove( MovieClipHit );
					
					if(hitId.indexOf(BLOOD_FLOW) > -1)
					{
						artEntity = _scene.getEntityById( hitId + "Art" );
						timeline = artEntity.get( Timeline );
						timeline.gotoAndPlay("start");
						entity.remove(Mover);
						node.damageTarget.isTriggered = true;
						EnemySpawn( node.entity.get( EnemySpawn )).max = 0;
						_scene.shellApi.triggerEvent( _events.CLOGGED_HAND_CUT_ + getNumber( node.id.id ), true );
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
		
		private function getNumber(id:String):String
		{
			var index:Number = id.indexOf("Target");
			
			return(id.slice( 9, index ));
		}
		
		public const BLOOD_FLOW:String = "bloodFlow";
		
		private var _scene:Scene;
		private var _events:VirusHunterEvents;
	}
}

