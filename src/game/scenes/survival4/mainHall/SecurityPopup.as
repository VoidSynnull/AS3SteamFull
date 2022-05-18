package game.scenes.survival4.mainHall
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.KeyboardCreator;
	import game.data.TimedEvent;
	import game.data.ui.ButtonData;
	import game.scene.template.AudioGroup;
	import game.scenes.carrot.shared.rabbotEars.components.Current;
	import game.scenes.carrot.shared.rabbotEars.systems.CurrentSystem;
	import game.scenes.survival4.Survival4Events;
	import game.ui.popup.Popup;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class SecurityPopup extends Popup
	{
		public function SecurityPopup( container:DisplayObjectContainer = null )
		{
			super( container );
			complete = new Signal( Popup );
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.init( container );
			super.groupPrefix = "scenes/survival4/mainHall/";
			super.pauseParent = true;
			super.autoOpen = false;
			this.hideSceneWhenOpen = true;
			load();
		}
		
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.loadFiles( new Array( "securityPanel.swf" ), false, true, loaded );
		}

		// all assets ready
		override public function loaded():void
		{
			super.screen = super.getAsset( "securityPanel.swf", true ) as MovieClip;
			this.fitToDimensions( super.screen.content, true );
			
			addSystem( new CurrentSystem( 3 ));
			
			_events = super.shellApi.islandEvents as Survival4Events;
			_audioGroup = parent.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			
			var asset:MovieClip = super.screen.content;
			var clip:MovieClip = asset[ "background" ];
			DisplayUtils.convertToBitmapSprite( clip, null, 2 );
			
			createKeys( super.screen );
			createLocks();
			
			loadCloseButton();
			super.shellApi.eventTriggered.add( eventTriggers );
			
			super.loaded();
			super.open();
			SceneUtil.lockInput( this, false );
		}
		
		/**
		 * Creates keys for keyboard, these are auto-positioned based on the layout Vector.
		 * NOTE :: Eventually would like to handle repositioned keyboards.
		 * @param container
		 * 
		 */
		private function createKeys( container:DisplayObjectContainer ):void
		{
			// get keyboard layout
			var layout:Vector.<Vector.<ButtonData>> = KeyboardCreator.getLayout( keyboardType );
			layout[ layout.length - 1 ].pop();
			
			// create keys
			var buttonData:ButtonData;
			var i:int;
			var j:int;
			var keyLabel:String;
			var col:int = 0;
			
			for ( i = layout.length - 2; i >= 0; i-- )
			{
				
				for ( j = 0; j <  layout[i].length; j++ )
				{
					buttonData = layout[i][j];
					buttonData.row = col;
					buttonData.column = j
					super.loadFile( "key.swf", onKeyAssetLoaded, buttonData, layout[i].length );
				}
				col++;
			}
			
			buttonData = layout[layout.length - 1][0];
			buttonData.row = 3;
			buttonData.column = 0;
			super.loadFile( "key.swf", onKeyAssetLoaded, buttonData, 3 );
		}
		
		//public function onKeyAssetLoaded( value:String, row:int, column:int ):void
		public function onKeyAssetLoaded( asset:DisplayObjectContainer, buttonData:ButtonData, totalColumns:int ):void
		{
			if ( !_buffer )
			{
				_buffer = asset.width * bufferRatio;
			}
			
			// this assumes that the keys are aligned to center, not top-left
			var startX:int = -((asset.width + _buffer) * totalColumns) * .5 + asset.width * .5;
			var x:int = startX + (asset.width + _buffer) * buttonData.column;
			var y:int = startY + (asset.height + _buffer) * buttonData.row + asset.height * .5;
			
			asset.scaleX = asset.scaleX * buttonData.unitWidth;
			asset.scaleY *= buttonData.unitHeight;
			
			var clip:MovieClip = MovieClip(asset).content;
			clip.x = x;
			clip.y = y;
			var buttonEntity:Entity = ButtonCreator.createButtonEntity( clip, this, Command.create(onKeyClicked, buttonData.value), MovieClip(super.screen).content.keyContainer );
			//var button:StandardButton = ButtonCreator.createStandardButton( clip, null, MovieClip(super.screen).content.keyContainer );
			Button(buttonEntity.get(Button)).value = buttonData.value;
			_audioGroup.addAudioToEntity( buttonEntity );
			
			if ( buttonData.labelText != "" )
			{
				// check if a labelContainer is within key
				var labelContainer:DisplayObjectContainer = clip.labelContainer;
				if( !labelContainer )
				{
					labelContainer = clip;
				}
				ButtonCreator.addLabel( labelContainer, buttonData.labelText, BUTTON_TEXT_FORMAT, ButtonCreator.ORIENT_CENTERED );
			}
		}
		
		// PAYS ATTENTION TO VOICE LOCK
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.TALLY_HO_DOWN )
			{
				var timeline:Timeline = _voiceLock.get( Timeline );
				timeline.gotoAndStop( 1 );
				
				var audio:Audio = _keyLock.get( Audio );
				audio.playCurrentAction( RANDOM );
			}
		}
		
		private function createLocks():void
		{
			var timeline:Timeline;
			
			_voiceLock = TimelineUtils.convertClip( super.screen.content.voiceLock, this );
			_audioGroup.addAudioToEntity( _voiceLock );
			var audio:Audio = _voiceLock.get( Audio );
			audio.playCurrentAction( RANDOM );
			
			if( shellApi.checkEvent( _events.TALLY_HO_DOWN ))
			{
				timeline = _voiceLock.get( Timeline );
				timeline.gotoAndStop( 1 );
			}
			
			_keyLock = TimelineUtils.convertClip( super.screen.content.keyLock, this );
			_audioGroup.addAudioToEntity( _keyLock );
			_masterLock = TimelineUtils.convertClip( super.screen.content.masterLock, this );
			_audioGroup.addAudioToEntity( _masterLock );
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
			{
				var current:Current = new Current( 242, 242, 0, 13, 5, 5, 75, 3, 0x00AD9F );
				
				if( shellApi.checkEvent( _events.TALLY_HO_DOWN ))
				{
					current.maxOffset = 15;
				}
				
				var grid:Entity = EntityUtils.createSpatialEntity( this, new Sprite(), super.screen.content.grid );
				grid.add( current );			
			}
			
			_readOut = new Vector.<TextField>;
			
			for( var number:int = 0; number < 4; number ++ )
			{
				_readOut.push( TextUtils.refreshText( super.screen.content.getChildByName( "digit" + number )));
				_readOut[ number ].embedFonts = true;
				_readOut[ number ].defaultTextFormat = READ_OUT_TEXT_FORMAT;
				
				_readOut[ number ].text = "_";
			}
		}
		
		public function onKeyClicked( buttonEntity:Entity, value:*  ):void
		{
			_readOut[ _currentDigit ].text = value;
			_currentDigit ++;
			var audio:Audio = buttonEntity.get( Audio );
			
			audio.playCurrentAction( KEYPRESS + ( Math.round( Math.random() * 2 ) + 1 ));
			
			if( _currentDigit == 4 )
			{
				SceneUtil.lockInput( this );
				checkPassword();	
			}
		}
		
		private function checkPassword():void
		{
			_currentDigit = 0;
			
			for( var number:int = 0; number < 4; number ++ )
			{
				_enteredPassword += _readOut[ number ].text.toString();
			}
			
			if( _enteredPassword == PASSWORD )
			{ 
				shellApi.triggerEvent( _events.CODE_ENTERED, true );
				
				var timeline:Timeline = _keyLock.get( Timeline );
				timeline.gotoAndStop( 1 );
				
				var audio:Audio = _keyLock.get( Audio );
				audio.playCurrentAction( RANDOM );
				
				if( shellApi.checkEvent( _events.TALLY_HO_DOWN ))
				{
					timeline = _masterLock.get( Timeline );
					timeline.gotoAndStop( 1 );
					
					audio = _masterLock.get( Audio );
					audio.playCurrentAction( RANDOM );
				}
				
				SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1 , correctPassword ));
			}
			
			else
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, blinkCode ));
			}
		}
		
		private function blinkCode( toDashes:Boolean = true ):void
		{
			if( toDashes )
			{
				var audio:Audio = _keyLock.get( Audio );
				audio.playCurrentAction( FAIL );
				
				_blinkNumber ++;
				for( var number:int = 0; number < 4; number ++ )
				{
					_readOut[ number ].text = "_";
				}
				
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, Command.create( blinkCode, false )));
			}
			else
			{
				if( _blinkNumber <= 2 )
				{
					for( number = 0; number < 4; number ++ )
					{
						_readOut[ number ].text = _enteredPassword.substr( number, 1 );
					}
				
					SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, blinkCode ));
				}
				else
				{
					for( number = 0; number < 4; number ++ )
					{
						_readOut[ number ].text = "_";
					}
					
					_blinkNumber = 0;
					_enteredPassword = "";
					_currentDigit = 0;
					
					SceneUtil.lockInput( this, false );
				}
			}
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			SceneUtil.lockInput( this, false );
			super.shellApi.eventTriggered.remove( this.eventTriggers );
			super.close();
		}
		
		private function correctPassword():void
		{
			complete.dispatch( this );
		}
		
		private var _voiceLock:Entity;
		private var _events:Survival4Events;
		private var _audioGroup:AudioGroup;
		private var _keyLock:Entity;
		private var _masterLock:Entity;
		private var _buffer:Number;
		private var _readOut:Vector.<TextField>;
		private var _blinkNumber:int = 0;
		private var _currentDigit:int = 0;
		
		private const PASSWORD:String = "0451";
		private const KEYPRESS:String =	"keypress";
		private const RANDOM:String =	"random";
		private const FAIL:String = 	"fail";
		private var _enteredPassword:String = "";
		
		public var complete:Signal;
		public var bufferRatio:Number = .12;
		public var keyboardType:String = KeyboardCreator.KEYBOARD_NUMERIC;
		public var startY:Number = 0;
		public var BUTTON_TEXT_FORMAT:TextFormat = new TextFormat( "Helvetica Bold", 30, 0x5A4A42 );
		public var READ_OUT_TEXT_FORMAT:TextFormat = new TextFormat( "LCDMono", 24, 0x000000 );
		
		// LCDMono
	}
}