package game.scenes.myth.apollo
{		
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.motion.Edge;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.ui.ToolTip;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.myth.shared.Flute;
	import game.scenes.myth.shared.MythScene;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class Apollo extends MythScene
	{
		public function Apollo()
		{
			super();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/myth/apollo/";
			
			super.init( container );
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
			
			super.addSystem( new TweenSystem(), SystemPriorities.update );
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			
			super.shellApi.eventTriggered.add( eventTriggers );
			var entity:Entity;
			var number:int;
			_isPlaying = false;
		
			for( number = 1; number < 7; number ++ )
			{
				entity = EntityUtils.createMovingEntity( this, _hitContainer[ "muse_note" + number ]);
				entity.add( new Id( "muse_note" + number ));
				
				_audioGroup.addAudioToEntity( entity );
				
				Display( entity.get( Display )).alpha = 0;
			}
			
			NOTE_SCALE_X = Spatial( entity.get( Spatial )).scaleX;
			NOTE_SCALE_Y = Spatial( entity.get( Spatial )).scaleY;
			
			if( super.shellApi.checkHasItem( REED_PIPE ))
			{
				super.removeEntity( super.getEntityById( "pipesInteraction" ));
				if( !super.shellApi.checkHasItem( PIPE_TUNE ))
				{					
					for( number = 1; number < 10; number ++ )
					{
						entity = super.getEntityById( "statue" + number );
						SceneInteraction( entity.get( SceneInteraction )).reached.add( lockAtStatue );
					}
				}
			}
			else
			{
				SceneInteraction( super.getEntityById( "pipesInteraction" ).get( SceneInteraction )).reached.removeAll();
				SceneInteraction( super.getEntityById( "pipesInteraction" ).get( SceneInteraction )).reached.add( getReedPipe );
			}
			
			if( super.shellApi.checkEvent( _events.SIMON_SAYS_FAILED ))
			{
				super.shellApi.removeEvent( _events.SIMON_SAYS_FAILED );
			}
		}
		
		override protected function addCharacterDialog( container:Sprite ):void
		{
			setupTalkingStatues();
			super.addCharacterDialog( container );
		}
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var entity:Entity;
			var audio:Audio;
			
			var number:int;
			
			trace( event );
			switch( event )
			{
				case _events.SIMON_START:
					entity = super.getEntityById( "sceneSound" );
					audio = entity.get( Audio );
					audio.fade( SoundManager.MUSIC_PATH + FLUTE_MUSIC, 0, 0.016666666666666666, 1, "music" );
					simonPopup();
					break;
				
				case _events.PLAY_MUSIC:
					if( !_isPlaying )
					{
						playNote();
						_isPlaying = true;
					}
					break;
			
				case _events.UNLOCK_MOTION:
					CharUtils.lockControls( player, false, false );
					
					for( number = 1; number < 10; number ++ )
					{
						entity = super.getEntityById( "statue" + number );
						Interaction( entity.get( Interaction )).lock = false;
						ToolTipCreator.addToEntity( entity );
					}
					break;
			}
		}
		
		
		/*******************************
		 * 	      PLAY MELODY
		 * *****************************/
		private function playNote():void
		{
			var entity:Entity = super.getEntityById( "muse_note" + _noteNumber );
			
			
			var display:Display = entity.get( Display );
			var spatial:Spatial = entity.get( Spatial );
			
			Motion( entity.get( Motion )).velocity.x = -20;
			
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "random" );
			
			var tween:Tween = new Tween();
			tween.from( spatial, .5, { scaleX : .5, scaleY : .5 });
			tween.to( display, .5, { alpha : 1, onComplete : Command.create( floatOn, entity )});
			
			entity.add( tween ).add( new Threshold( "x", "<" ));
			_noteNumber++;
		}
		
		private function floatOn( entity:Entity ):void
		{
			var threshold:Threshold = entity.get( Threshold );
			var number:int; 
			var statue:Entity;
						
			if( _noteNumber < 7 )
			{
				if( _noteNumber == 3 )
				{
					SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, playNote ));	
				}
				else
				{
					playNote();
				}
				
				threshold.threshold = NOTE_THRESHOLD;
				threshold.entered.addOnce( Command.create( fadeOutNote, entity ));
			}
			else
			{
				threshold.threshold = NOTE_THRESHOLD;
				threshold.entered.addOnce( Command.create( fadeOutNote, entity ));
				
				if( !super.shellApi.checkHasItem( PIPE_TUNE ))
				{
					super.shellApi.getItem( PIPE_TUNE, null, true );
					
					for( number = 1; number < 10; number ++ )
					{
						entity = super.getEntityById( "statue" + number );
						SceneInteraction( entity.get( SceneInteraction )).reached.remove( lockAtStatue );
					}
					
					SceneUtil.lockInput( this, false );
					CharUtils.lockControls( super.shellApi.player, false, false );
					
					for( number = 1; number < 10; number ++ )
					{
						statue = super.getEntityById( "statue" + number );
						Interaction( statue.get( Interaction )).lock = false;
						ToolTipCreator.addToEntity( entity );
					}
				}
			}
		}
		
		private function fadeOutNote( entity:Entity ):void
		{
			var tween:Tween = entity.get( Tween );
			
			var display:Display = entity.get( Display );
			var spatial:Spatial = entity.get( Spatial );
			
			_fadedNotes++;
			
			tween.to( spatial, .5, { scaleX : .5, scaleY : .5 });
			if( _fadedNotes < 6 )
			{
				tween.to( display, .5, { alpha : 0 });
			}
			else
			{
				tween.to( display, .5, { alpha : 0, onComplete : resetNotes });
			}
		}
		
		private function resetNotes():void
		{
			var entity:Entity;
			var spatial:Spatial;
			var number:int;
			
			for( number = 1; number < 7; number ++ )
			{
				entity = super.getEntityById( "muse_note" + number );
				
				spatial = entity.get( Spatial );
				spatial.x = NOTE_X;
				spatial.scaleX = NOTE_SCALE_X;
				spatial.scaleY = NOTE_SCALE_Y;
				
				Display( entity.get( Display )).alpha = 0;
				
				entity.remove( Threshold );
				entity.remove( Tween );
				
				Motion( entity.get( Motion )).velocity.x = 0;
			}
			
			_noteNumber = 1;
			_fadedNotes = 0;
			
			_isPlaying = false;
		}
		
		/*******************************
		 * 	      MUSE STATUES
		 * *****************************/
		private function setupTalkingStatues():void
		{
			var dialog:Dialog;
			var entity:Entity;
			var number:int;
			
			for( number = 1; number < 10; number ++) 
			{
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "statue" + number ]);
				dialog = new Dialog()
				dialog.faceSpeaker = true;
				dialog.dialogPositionPercents = new Point( 0, .5 );				
				entity.add( dialog );
				entity.add( new Id( "statue" + number ));
				entity.add( new Edge( 50, 50, 50, 80 ));
				
				var character:Character = new Character();
				character.costumizable = false;
				entity.add(character);		
				ToolTipCreator.addToEntity( entity );
				
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.offsetX = 50;
				sceneInteraction.offsetY = 135;
				entity.add( sceneInteraction );		
			}
		}
		
		private function lockAtStatue( char:Entity, statue:Entity ):void
		{
			CharUtils.lockControls( player );
			
			var number:int;
			var entity:Entity;
			
			for( number = 1; number < 10; number ++ )
			{
				entity = super.getEntityById( "statue" + number );
				Interaction( entity.get( Interaction )).lock = true;
				entity.remove( ToolTip );
			}
		}
		
		/*******************************
		 * 	    FLUTE AND SIMON
		 * *****************************/
		private function getReedPipe( char:Entity, pipe:Entity ):void
		{
			super.shellApi.getItem( REED_PIPE, null, true );
			
			super.removeEntity( super.getEntityById( "pipesInteraction" ));
			var number:int;
			var entity:Entity;
			
			for( number = 1; number < 10; number ++ )
			{
				entity = super.getEntityById( "statue" + number );
				SceneInteraction( entity.get( SceneInteraction )).reached.add( lockAtStatue );
			}
			
			super.removeEntity( pipe );
		}
		
		private function simonPopup():void
		{
			var popup:Flute = super.addChildGroup( new Flute( super.overlayContainer, true )) as Flute;
			popup.id = "flute";
			
			popup.complete.add( Command.create( completeFlute, popup ));
			popup.fail.add( Command.create( failFlute, popup ));
			popup.closeClicked.add( quitFlute );
		}
		
		private function completeFlute( popup:Flute ):void
		{
			var entity:Entity = super.getEntityById( "sceneSound" );
			var audio:Audio = entity.get( Audio );
			
			popup.close();
			
			audio.play( SoundManager.MUSIC_PATH + FLUTE_MUSIC, true, SoundModifier.FADE );
			shellApi.triggerEvent( _events.SIMON_SAYS_PASSED, true );
		}
		
		private function failFlute( popup:Flute ):void
		{
			var entity:Entity = super.getEntityById( "sceneSound" );
			var audio:Audio = entity.get( Audio );
			
			popup.close();	
			
			audio.play( SoundManager.MUSIC_PATH + FLUTE_MUSIC, true, SoundModifier.FADE );
			shellApi.triggerEvent( _events.SIMON_SAYS_FAILED, true );
		}
		
		private function quitFlute( popup:Flute ):void
		{
			var entity:Entity = super.getEntityById( "sceneSound" );
			var audio:Audio = entity.get( Audio );
			
			audio.play( SoundManager.MUSIC_PATH + FLUTE_MUSIC, true, SoundModifier.FADE );
			shellApi.triggerEvent( _events.SIMON_SAYS_QUIT );
			shellApi.triggerEvent( _events.UNLOCK_MOTION );
		}
		
		private const FLUTE_MUSIC:String = "apollo_flute.mp3";
		
		private const REED_PIPE:String = "reedPipe";
		private const PIPE_TUNE:String = "pipeTune";
		
		private const NOTE_THRESHOLD:Number = 1880;
		private const NOTE_X:Number = 1947.75;
		private var NOTE_SCALE_X:Number;
		private var NOTE_SCALE_Y:Number; 
		
		private var _isPlaying:Boolean;
		private var _noteNumber:int = 1;
		private var _fadedNotes:int = 0;
	}
}
