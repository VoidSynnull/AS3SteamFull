package game.scenes.backlot.soundStage4
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.motion.Threshold;
	import game.components.hit.Zone;
	import game.data.TimedEvent;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.scenes.backlot.BacklotEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.cityDestroy.CityDestroy;
	import game.scenes.backlot.extSoundStage2.Swing;
	import game.scenes.backlot.extSoundStage2.SwingSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class SoundStage4 extends PlatformerGameScene
	{
		public function SoundStage4()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/soundStage4/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();	
			_events = super.events as BacklotEvents;
			super.shellApi.eventTriggered.add( eventTriggers );
			
			var entity:Entity;
			var dialog:Dialog;
			var zone:Zone;
			
			// need to test this on real game to see what it looks like before/after
			if( !super.shellApi.checkEvent( _events.COMPLETE_STAGE_4 ))
			{
				if( !super.shellApi.checkEvent( _events.OFFERED_PART_STAGE_4 ))
				{
					SceneUtil.lockInput( this );
					entity = super.getEntityById( "carson" );
					dialog = entity.get( Dialog );
					
					dialog.sayById( "suit_up" );
					dialog.complete.addOnce( moveKirk );
				}
				else
				{
					entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "head" ]);
					entity.add( new Id( "head" ));
					EntityUtils.position( entity, 1476, 940 );
					
					entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "body" ]);
					entity.add( new Id( "body" ));
					EntityUtils.position( entity, 1456, 940 );
					
					entity = super.getEntityById( "costumeZone" );
					zone = entity.get( Zone );
					zone.entered.addOnce( putOnCostume );
				}
			}
			
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.addSystem( new SwingSystem( player ), SystemPriorities.move );
			
			setupSwingingObjects();
		}
		
		/*******************************
		 *     SCENE SETUP & UTILS
		 * *****************************/
		private function setupSwingingObjects():void
		{
			var entity:Entity;
				
			entity = EntityUtils.createMovingEntity( this, _hitContainer["swingHelicopter" ]);
			entity.add( new Swing());
			
			entity = EntityUtils.createMovingEntity( this, _hitContainer["swingPlane" ]);
			entity.add( new Swing());
		}
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var zone:Zone;
			var entity:Entity;
			
			if( event == _events.KIRK_QUITS )
			{
				kirkQuits();
			}
			
			if( event == _events.OFFERED_PART_STAGE_4 )
			{
				activateGorillaSuit();
				SceneUtil.lockInput( this, false );
			}
			
			if( event == _events.READY_TO_DESTROY_CITY )
			{
				entity = super.getEntityById( "stageZone" );
				zone = entity.get( Zone );
				zone.entered.addOnce( lightsCameraAction );
			}
		}
		
		private function playerTurns( faceRight:Boolean = true ):void
		{
			if( faceRight )
			{
				CharUtils.setDirection( player, true );
			}
			else
			{
				CharUtils.setDirection( player, false );
			}
		}
		
		/*******************************
		 *  	 KIRK SUITS UP
		 * *****************************/
		private function moveKirk( dialogData:DialogData ):void
		{
			var entity:Entity = super.getEntityById( "kirk" );
			
			var threshold:Threshold = new Threshold( "x", ">" );
			threshold.threshold = 1800;
			threshold.entered.addOnce( playerTurns );
			entity.add( threshold );
			
			CharUtils.moveToTarget( entity, 2061, 972, true, putOnSuit );
		}
		
		private function putOnSuit( entity:Entity ):void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, kirkInMonkeySuit ));
		}
		
		private function kirkInMonkeySuit():void
		{
			var entity:Entity = super.getEntityById( "kirk" );
			
			var lookAspect:LookAspectData;
			var lookData:LookData = new LookData();
			var threshold:Threshold = entity.get( Threshold );
			
			lookAspect = new LookAspectData( SkinUtils.MOUTH, 5 );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.MARKS, "shadow1" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.FACIAL, "bl_gorilla" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.HAIR, "hobo" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.SHIRT, "hobo" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.PANTS, "spanishcon" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.OVERSHIRT, "bl_gorilla" );
			lookData.applyAspect( lookAspect );
			
			SkinUtils.applyLook( entity, lookData, true );
			CharUtils.moveToTarget( entity, 1696, 962, true, kirkHasHadIt );
			
			threshold.operator = "<";
			threshold.threshold = 1800;
			threshold.entered.addOnce( Command.create( playerTurns, false ));
		}
		
		/*******************************
		 *  	  KIRK QUITS
		 * *****************************/
		private function kirkHasHadIt( entity:Entity ):void
		{
			var dialog:Dialog = entity.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.sayById( "monkey_suit" );
		}
		
		private function kirkQuits():void
		{
			var entity:Entity = super.getEntityById( "kirk" );
			
			var threshold:Threshold = entity.get( Threshold );
			threshold.threshold = 1800;
			threshold.entered.addOnce( playerTurns );
			
			CharUtils.moveToTarget( entity, 2061, 972, true, takeOffSuit );
		}
		
		private function takeOffSuit( entity:Entity ):void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, tossAsideMonkeySuit ));
		}
		
		private function tossAsideMonkeySuit():void
		{
			var entity:Entity;
			var motion:Motion;
			var threshold:Threshold;
			var tween:Tween;
			var spatial:Spatial;
			
			entity = EntityUtils.createMovingEntity( this, _hitContainer[ "head" ]);
			spatial = entity.get( Spatial );
			
			motion = entity.get( Motion );
			
			motion.velocity.x = -600;
			motion.velocity.y = -240;
			motion.rotationVelocity = -25;
			motion.acceleration = new Point( 4, 500 );
			
			threshold = new Threshold( "y", ">" );
			threshold.threshold = 940;
			threshold.entered.addOnce( Command.create( costumeLanded, entity ));
			entity.add( threshold ).add( new Id( "head" ));
		
			entity = EntityUtils.createMovingEntity( this, _hitContainer[ "body" ]);
			spatial = entity.get( Spatial );
			
			motion = entity.get( Motion );
			
			motion.velocity.x = -600;
			motion.velocity.y = -280;
			motion.rotationVelocity = 25;
			motion.acceleration = new Point( 3.75, 560 );
			
			threshold = new Threshold( "y", ">" );
			threshold.threshold = 940;
			threshold.entered.addOnce( Command.create( costumeLanded, entity ));
			entity.add( threshold ).add( new Id( "body" ));
		}
	
		private function costumeLanded( entity:Entity ):void
		{
			entity.remove( Motion );
			
			var spatial:Spatial = entity.get( Spatial );
			var stopPosition:Number; 
			
			if( spatial.x < 1456 )
			{
				stopPosition = spatial.x - 10;
			}
			else
			{
				stopPosition = 1470;
			}
			
			var tween:Tween = new Tween();
			
			tween.to( spatial, 1, { x : stopPosition, onComplete : stopCostume });
			entity.add( tween );
		}
		
		private function stopCostume():void
		{
			var entity:Entity;
			var dialog:Dialog;
			costumeStopped ++;
			
			if( costumeStopped == 2 )
			{
				entity = super.getEntityById( "carson" );
				dialog = entity.get( Dialog );
				dialog.sayById( "sigh" );
			}
		}
		
		/*******************************
		 *    PLAYER TAKES THE LEAD
		 * *****************************/
		private function activateGorillaSuit():void
		{
			var entity:Entity;
			var zone:Zone;
			
			entity = super.getEntityById( "costumeZone" );
			zone = entity.get( Zone );
			zone.entered.addOnce( putOnCostume );
		}
		
		private function putOnCostume( zoneId:String, entityId:String ):void
		{
			AudioUtils.play(this,"effects/cloth_flap_02.mp3");
			
			var lookAspect:LookAspectData;
			var lookData:LookData = new LookData();
			
			lookAspect = new LookAspectData( SkinUtils.MOUTH, 5 );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.MARKS, "shadow1" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.FACIAL, "bl_gorilla" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.HAIR, "hobo" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.SHIRT, "hobo" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.PANTS, "spanishcon" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.OVERSHIRT, "bl_gorilla" );
			lookData.applyAspect( lookAspect );
			
			SkinUtils.applyLook( player, lookData, false );
			
			super.removeEntity( super.getEntityById( "head" ));
			super.removeEntity( super.getEntityById( "body" ));
			
			super.shellApi.triggerEvent( _events.IN_COSTUME );
		}
		
		
		private function lightsCameraAction( zoneId:String, entityId:String ):void
		{
			super.shellApi.loadScene( CityDestroy, 450, 2413 );  
		}
		
		private var costumeStopped:int = 0;
		private var _events:BacklotEvents;
	}
}