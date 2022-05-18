package game.scenes.virusHunter.mouthShip.systems
{	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.hit.Radial;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.mouthShip.MouthShip;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class MouthTargetSystem extends GameSystem
	{
		public function MouthTargetSystem( scene:Scene, events:VirusHunterEvents )
		{
			super( SceneWeaponTargetNode, updateNode );
			_scene = scene as MouthShip;
			_events = events;
			
			
		}
		private function updateNode( node:SceneWeaponTargetNode, time:Number ):void
		{
			if( node.collider.isHit && !node.damageTarget.isTriggered )
			{
				var id:String = removeTarget( node.id.id );
				var entity:Entity = _scene.getEntityById( id );
				var tween:Tween;
				
				if(id.indexOf("tooth") > -1 && node.collider._colliderId == "scalpel")
				{
					var frame:uint = Math.ceil( 4 * ( node.damageTarget.damage / node.damageTarget.maxDamage ));
					var tooth:Entity = _scene.getEntityById( id + "Art" );
					var timeline:Timeline = tooth.get( Timeline );
					
					var toothSpatial:Spatial = tooth.get( Spatial );
					timeline.gotoAndStop( frame );
					_scene.shellApi.completeEvent( _events.TOOTH_CHIPPED_ + frame );
					
					var hazardEntity:Entity = _scene.getEntityById( "toothHazard" );
				
					var chip:Entity = _scene.getEntityById( "chip" + _scene.currentChip );
					
					Timeline( chip.get(Timeline )).gotoAndStop( Utils.randNumInRange( 0, 7 ));
					Display( chip.get( Display )).alpha = 1;
					
					var spatial:Spatial = chip.get( Spatial );
					spatial.x = toothSpatial.x + Utils.randNumInRange( -125, 125 );
					spatial.y = toothSpatial.y + Utils.randNumInRange( -125, 125 );
					spatial.scale = Math.random();
					
					var motion:Motion = chip.get( Motion );
					motion.velocity.x = Utils.randNumInRange( -175, 175 );
					motion.velocity.y = Utils.randNumInRange( -200, 300 );
					motion.rotationVelocity = Utils.randNumInRange( -400, 400 );
					motion.pause = false;
					
					SceneUtil.addTimedEvent( _scene, new TimedEvent( 1, 40, Command.create( chipTooth, chip )));
					
					var sound:String;
					var audio:Audio;
					
					sound = CALC_HIT;
					audio = entity.get(Audio);
					
					if( audio == null )
					{
						audio = new Audio();
						
						entity.add(audio);
					}
					if( !audio.isPlaying( SoundManager.EFFECTS_PATH + sound ))
					{
						audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
					}
					
					if( _scene.currentChip >= _scene.numChips ) _scene.currentChip = 1;
					else _scene.currentChip++;
				}
				
				if( node.damageTarget.damage >= node.damageTarget.maxDamage )
				{ 
					if( id == TOOTH )
					{
						entity.remove( Radial );
						node.damageTarget.isTriggered = true;
						_scene.shellApi.triggerEvent( _events.TOOTH_REMOVED, true );
						_scene.playMessage( "mouth_resolved", false, "mouth_resolved", "drLang" );
						
						removeEntity( entity );
						removeEntity( _scene.getEntityById( node.id.id ));
						removeEntity( _scene.getEntityById( id + "Art" ));
						removeEntity( _scene.getEntityById( id + "Hazard" ));
					}
				}
			}
		}
		
		private function chipTooth( chip:Entity ):void
		{
			var display:Display = chip.get(Display);
			display.alpha -= 0.025;
			if(display.alpha <= 0) chip.get(Motion).pause = true;			
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
		
		public const TOOTH:String = "tooth";
		static private const CALC_HIT:String = "stone_impact_01.mp3";
		private var _scene:MouthShip;
		private var _events:VirusHunterEvents;
	}
}

