package game.scenes.myth.shared
{	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.ui.WordBalloonCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.SoarDown;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	
	public class Athena extends Popup
	{
		public function Athena( container:DisplayObjectContainer=null )
		{
			super( container );
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.darkenBackground = true;
			super.autoOpen = false;
			super.groupPrefix = "scenes/myth/shared/";
			super.init( container );
			_currentDialogEvent = shellApi.sceneName.toLowerCase();
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "athena.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "athena.swf", true ) as MovieClip;
			DisplayUtils.convertToBitmapSprite( screen.content.scroll, null, 2 );
			this.layout.centerUI( super.screen.content );
			loadCloseButton();
			shellApi.triggerEvent( "open_scroll" );
			
			var characterGroup:CharacterGroup = new CharacterGroup();
			var charContainer:DisplayObjectContainer = super.screen.content;
			characterGroup.addToolTips = false;
			characterGroup.setupGroup( this, charContainer, super.getData( "npcs.xml" ), onCharactersLoaded );
			
			characterDialogGroup = parent.getGroupById( "characterDialogGroup" ) as CharacterDialogGroup;
			setupScroll();
			// load the characters into the the groupContainer instead of the hitContainer since this isn't a platformer scene with camera layers.
			
			super.addSystem( new ElectrifySystem, SystemPriorities.update );
			super.addSystem( new WaveMotionSystem, SystemPriorities.move );
		}
		
		protected function onCharactersLoaded():void
		{
			_athena = super.getEntityById( "athena" );
			characterDialogGroup.assignDialog( _athena );
			
			var audioGroup:AudioGroup = getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( _athena );
			var audio:Audio = _athena.get( Audio );
			audio.playCurrentAction( "random" );
			
			var display:Display = _athena.get( Display );
			var electrify:ElectrifyComponent = new ElectrifyComponent();
			var sprite:Sprite;
			var startX:Number;
			var startY:Number;
			var spatial:Spatial = _athena.get( Spatial );
			
			// Set her animation to the end of SoarDown
			CharUtils.setAnim( _athena, SoarDown);
			var timeline:Timeline = getEntityById( "athena" ).get( Timeline );
			timeline.gotoAndStop( 9 );
			
			// Add flashy filters to her display
			if(!PlatformUtils.isMobileOS)
			{
				var colorFill:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 100, 100, 1, 1, true );
				var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
				var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true );
				
				var filters:Array = new Array( colorFill, whiteOutline, colorGlow );
				display.displayObject.filters = filters;
			}
			
			// Add her slight up/down bobbing
			var waveMotion:WaveMotion = new WaveMotion();
			var waveMotionData:WaveMotionData = new WaveMotionData( "y", 10, .02 );
			waveMotion.add( waveMotionData );
			
			// position background glow
			var background:MovieClip = screen.bg;
			
			background.width = shellApi.viewportWidth;
			background.height = shellApi.viewportHeight;
			
			background.x = .5 * shellApi.viewportWidth;
			background.y = .5 * shellApi.viewportHeight;
			// Electrify athena
			for( var number:int = 0; number < 10; number ++ )
			{
				sprite = new Sprite();
				startX = Math.random() * 120 - 60;
				startY = Math.random() * 280 - 140;
				
				sprite.graphics.lineStyle( 1, 0xFFFFFF );
				sprite.graphics.moveTo( startX, startY );
				
				electrify.sparks.push( sprite );
				electrify.lastX.push( startX );
				electrify.lastY.push( startY );
				electrify.childNum.push( display.displayObject.numChildren );
				
				display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
			}
			
			_athena.add( waveMotion ).add( electrify ).add( new SpatialAddition());
			super.loaded();
//			spatial.scale = .55;
//			
//			SkinUtils.setSkinPart( _athena, "hair", "athena" );
//
//			var characterCreator:CharacterCreator = new CharacterCreator();
//			var lookData:LookData = new LookData();
//			lookData.applyLook( "female", 0xE6BC7D, 0x0, "squint", "athena", "athena", "", "athena", "athena", "athena", "athena", "", "athena" );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .25, 1, triggerPopup ));	
		}
		
		private function triggerPopup():void
		{	
			super.open();
			triggerDialogue();
		}
		
		private function setupScroll():void
		{
			var checkBox:Entity; 
			var timeline:Timeline;
			var item:String;
			var number:int;
			
			var data:DialogData;
			var textFormat:TextFormat = new TextFormat( "WebLetterer BB", 18, 0x643408, false, false, false, null, null, "center", null, 0, null, 0 );
			
			data = characterDialogGroup.allDialogData[ "athena" ][ _currentDialogEvent ];
			if( data != null )
			{
				_textField = TextUtils.refreshText( screen.content.text );
				
				_textField.embedFonts = true;
				_textField.wordWrap = true;
				_textField.defaultTextFormat = textFormat;
				
				_textField.text = data.dialog;
				
				if( _currentDialogEvent != "mountolympus" )
				{
					_textField.y += 30;
				}
			}
			
//			DisplayUtils.convertToBitmapSpriteBasic( screen.content.scroll, null, 2 );
		}
	
		protected function triggerDialogue():void
		{
			Sleep( _athena.get( Sleep )).sleeping = false;
			
			var dialog:Dialog = _athena.get( Dialog ) as Dialog;
			dialog.allowOverwrite = true;
			var dialogData:DialogData = DialogData( dialog.getDialog( _currentDialogEvent ));
			
			updateTalkAnimation( _athena );
	
			showDialog(dialogData);
		}
		
		protected function updateTalkAnimation( on:Boolean = true ):void
		{
			var skin:Skin = _athena.get( Skin );
			
			if( skin )
			{
				var mouth:SkinPart = skin.getSkinPart( SkinUtils.MOUTH );
				var eyeState:SkinPart = skin.getSkinPart( SkinUtils.EYE_STATE );
				
				if( on )
				{
					mouth.setValue( "talk", false );
					eyeState.setValue( "casual", false );
					eyeState.lock = true;		// lock assets, unlock once talking is finished	
					mouth.lock = true;
					
					CharUtils.stateDrivenOn( _athena, true );
				}
				else
				{
					if( mouth.value == "talk" )
					{
						mouth.lock = false;
						eyeState.lock = false;
						mouth.revertValue();
						eyeState.revertValue();
						
						CharUtils.stateDrivenOff( _athena, TALK_DELAY );
					}
				}
			}
		}
		
		protected function showDialog( dialogData:DialogData ):void
		{
			if( _dialogTimedEvent!= null ) 
			{ 
				_dialogTimedEvent.stop(); 
			}
			
			_textField.text = dialogData.dialog;
			
			var time:Number = dialogData.timeOverride;
			
			if( isNaN( time ))
			{
				time = WordBalloonCreator.getDialogTime( dialogData.dialog, shellApi.profileManager.active.dialogSpeed );
			}
			
			_dialogTimedEvent = SceneUtil.addTimedEvent( this, new TimedEvent( time, 1, Command.create( onDialogComplete, dialogData )));
		}
		
		protected function onDialogComplete( dialog:DialogData = null ):void
		{
			updateTalkAnimation( false );
		}
		
		private const TALK_DELAY:int = 90;
		
		private var _dialogTimedEvent:TimedEvent;
		private var _athena:Entity;
		private var _textField:TextField;
		private var _currentDialogEvent:String;
		
		private var characterDialogGroup:CharacterDialogGroup;
	}
}