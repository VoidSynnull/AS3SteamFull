package game.scenes.myth.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.components.Interaction;
	
	import game.components.input.Input;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scenes.myth.MythEvents;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class Flute extends Popup
	{
		public function Flute( container:DisplayObjectContainer = null, playingSimon = false )
		{
			_playingSimon = playingSimon;
			super( container );
		}	
		
		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			remove();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		override public function destroy():void
		{
			lockInput( false );
						
			complete.removeAll();
			complete = null;
			
			fail.removeAll();
			fail = null;
			
			_mazeNotes = null;
			_correctNotes = null;
			_notes = null;
			
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			complete = new Signal();
			fail = new Signal();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/shared/";
			super.init( container );
			super.autoOpen = false;
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "flute.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "flute.swf", true ) as MovieClip;
			super.layout.centerUI( super.screen.content );
			loadCloseButton();
			
			// Arrays of correct notes
			_mazeNotes.push( 1, 1, 2, 3, 3, 4, 1, 2 );
			_correctNotes.push( 1, 2, 3, 1, 4, 2 );
			
			fluteNotes();
			
			super.loaded();
			super.open();
			
			if( _playingSimon )
			{
				startSimon();
			}
			else if( super.shellApi.sceneName == "Cerberus" || super.shellApi.sceneName == "Hydra" )
			{
				_soothingMelody = true;
			}
			else if( super.shellApi.sceneName == "Sphinx" )
			{
				_doorJam = true;
			}
		}
		
		private function fluteNotes():void
		{
			var clip:MovieClip;
			var entity:Entity;
			var interaction:Interaction;
			var number:int;
			var timeline:Timeline;
			
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
						
			for( number = 1; number < 5; number ++ )
			{
				clip =  MovieClip( MovieClip( super.screen.content ).getChildByName( "note" + number ));
				entity = ButtonCreator.createButtonEntity( clip, this, playNote );
				entity.add( new Id( "note" + number ));
				
				audioGroup.addAudioToEntity( entity );
				
				timeline = entity.get( Timeline );				
				timeline.gotoAndStop( 0 );
			}
		}
		
		private function playNote( entity:Entity ):void
		{
			if(( !locked && _playingSimon ) || !_playingSimon )
			{
				var timeline:Timeline = entity.get( Timeline );
				timeline.gotoAndStop( 1 );
				
				var audio:Audio = entity.get( Audio );
				audio.playCurrentAction( "random" );
				
				endNote(entity);
			}
		}
		
		// Determine which array to solve against
		private function endNote(entity:Entity ):void
		{
			var interaction:Interaction;
			interaction = entity.get( Interaction );
			
			var noteNum:int = int( Id( entity.get( Id )).id.slice( 4 ));
			var timeline:Timeline = entity.get( Timeline );
			timeline.gotoAndStop( 0 );
			
			
			if( _playingSimon )
			{
				if( noteNum == _notes[ playbackNum ])
				{
					playbackNum ++;
					if( playbackNum == 8 )
					{
						locked = true;
						lockInput( locked );
						SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, completeFlute ));
					}
					else 
					{
						if( playbackNum == curPos )
						{
							playbackNum = 0;
							addedNote = false;
							startSimon();
							SceneUtil.addTimedEvent( this, new TimedEvent( 0.1, 1, resetNoteStates ));
						}
					}	
				}
				else
				{
					locked = true;
					lockInput( locked );
					SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, failFlute ));
				}
			}
				
			else if( _soothingMelody )
			{
				if( noteNum == _correctNotes[ playbackNum ])
				{
					playbackNum ++;
					if( playbackNum == _correctNotes.length )
					{
						super.shellApi.triggerEvent( _events.SOOTHING_MELODY );
						close();
					}
				}
				else
				{
					playbackNum = 0;
				}
			}
				
			else if( _doorJam )
			{
				if( noteNum == _mazeNotes[ playbackNum ])
				{
					playbackNum ++;
					if( playbackNum == _mazeNotes.length )
					{
						super.shellApi.triggerEvent( _events.DOOR_JAM );
						close();
					}
				}
				else
				{
					playbackNum = 0;
				}
			}
		}
		
		private function resetNoteStates():void
		{
			for( var number:int = 1; number < 5; number ++ )
			{
				var entity:Entity = super.getEntityById( "note" + number );
				var timeline:Timeline = entity.get( Timeline );
				timeline.gotoAndStop( 0 );
			}
		}
		
		// Simon says code
		private function startSimon():void 
		{
			locked = true;
			lockInput( locked );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, addNote ));
		}
		
		private function addNote():void 
		{ 
			curNote = Math.ceil( Math.random() * 4 );
			curPos ++;
			addedNote = true;
			
			_notes.push( curNote );
			playBackNotes();
		}	
		
		private function playBackNotes():void
		{
			var entity:Entity;
			var timeline:Timeline;
			
			entity = super.getEntityById( "note" + _notes[ playbackNum ]);
			timeline = entity.get( Timeline );
			timeline.gotoAndStop( 1 );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "random" );
			
			playbackNum ++;
				
			SceneUtil.addTimedEvent( this, new TimedEvent( DELAY, 1, resetNotes ));
		}
		
		private function resetNotes():void
		{
			var entity:Entity;
			var timeline:Timeline;
			var number:Number;
			
			for( number = 1; number < 5; number ++ )
			{
				entity = super.getEntityById( "note" + number );
				timeline = entity.get( Timeline );
				
				timeline.gotoAndStop( 0 );
			}
			
			if( playbackNum < curPos )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( MID_SONG_DELAY, 1, playBackNotes ));
			}
			
			else
			{
				if( !addedNote )
				{
					SceneUtil.addTimedEvent( this, new TimedEvent( MID_SONG_DELAY, 1, addNote ));
				}
				else
				{
					playbackNum = 0;
					SceneUtil.addTimedEvent( this, new TimedEvent( MID_SONG_DELAY, 1, unlock ));
				}
			}
		}
		
		private function unlock():void
		{
			locked = false;
			lockInput( locked );
		}
		
		private function compareVectors( array1:Vector.<int>, array2:Vector.<int> ):Boolean 
		{
			var number:int;
			
			for ( number = array2.length - 1; number >= 0; number-- ) 
			{
				if ( array1[ number ] != array2[ number ]) 
				{
					return false;
				}
			} 
			
			return true;
		}
		private function lockInput( locked:Boolean ):void
		{
			var input:Input 		= this.shellApi.inputEntity.get(Input);
			input.lockInput 		= locked;
			input.lockPosition 		= locked;
			input.inputActive 		= false;
			input.inputStateDown 	= false;
		}
		
		private function failFlute():void
		{
			fail.dispatch();
		}
		
		private function completeFlute():void
		{
			complete.dispatch();
		}
				
		public var complete:Signal;
		public var fail:Signal;
		
		private var locked:Boolean = true;
		
		private var _events:MythEvents = new MythEvents;
		
		private var _mazeNotes:Vector.<int> = new Vector.<int>;
		private var _correctNotes:Vector.<int> = new Vector.<int>;
		private var _notes:Vector.<int> = new Vector.<int>;
		
		private var curPos:int = 0;
		private var curNote:int;
		private var addedNote:Boolean = false;
		private var playbackNum:int;
		
		private const MAX_NOTES:int = 8;
		private const DELAY:Number = .5;
		private const MID_SONG_DELAY:Number = .2;
		
		private var _playingSimon:Boolean;
		private var _doorJam:Boolean = false;
		private var _soothingMelody:Boolean = false;
	}
}
