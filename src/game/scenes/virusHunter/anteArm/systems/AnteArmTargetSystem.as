package game.scenes.virusHunter.anteArm.systems
{
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Tween;
	import engine.components.EntityType;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Mover;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	
	public class AnteArmTargetSystem extends GameSystem
	{
		public function AnteArmTargetSystem( scene:Scene, events:VirusHunterEvents )
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
				
				var sound:String;
				var audio:Audio = entity.get(Audio);
			
				if( hitId.indexOf(BLOOD_FLOW) > -1 && ( node.collider.collider.get( EntityType ).type == "goo" ))
				{
					if( node.damageTarget.damage >= node.damageTarget.maxDamage )
					{ 
						node.entity.remove( MovieClipHit );
					
						artEntity = _scene.getEntityById( hitId + "Art" );
						timeline = artEntity.get( Timeline );
						timeline.gotoAndPlay("start");
						entity.remove(Mover);
						
						sound = "squish_07.mp3"
							
						if( audio == null )
						{
							audio = new Audio();
							
							entity.add(audio);
						}
						
						audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
						
						node.damageTarget.isTriggered = true;
						EnemySpawn( node.entity.get( EnemySpawn )).max = 0;
						_scene.shellApi.completeEvent( _events.CLOGGED_UPPER_ARM_CUT_ + getNumber( node.id.id ));
					}
					
					else
					{
						sound = "squish_08.mp3";
						if( audio == null )
						{
							audio = new Audio();
							
							entity.add(audio);
						}
						
						audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
					}
				}
			}
		}
		
		private function removeEntity( entity:Entity ):void
		{
			_scene.removeEntity( entity );
		}
		
		override public function addToEngine( systemManager:Engine ) : void
		{
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ) : void
		{
			systemManager.releaseNodeList( SceneWeaponTargetNode );
			super.removeFromEngine( systemManager );
		}
		
		private function removeTarget( id:String ):String
		{
			var index:Number = id.indexOf( "Target" );
			
			return( id.slice( 0, index ));
		}
		
		private function getNumber( id:String ):int
		{
			return( int( id.charAt( 9 )));
		}
		
		public const MUSCLE:String = "muscle";
		public const NERVE:String = "nerve";
		public const BLOOD_FLOW:String = "bloodFlow";
		public const FAT:String = "fat";
		private var _scene:Scene;
		private var _events:VirusHunterEvents;
	}
}
