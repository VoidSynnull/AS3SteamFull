package game.scenes.examples.characterPopup
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Strong;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.ui.ProgressBar;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.KeyboardCreator;
	import game.data.TimedEvent;
	import game.data.ui.TransitionData;
	import game.scene.template.PlatformerGameScene;
	import game.ui.elements.ProgressBox;
	import game.ui.keyboard.KeyboardPopup;
	import game.ui.popup.CharacterDialogWindow;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	
	
	public class CharacterPopup extends PlatformerGameScene
	{
		public function CharacterPopup()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/characterPopup/";
			
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
			setupExampleButtons();
			super.shellApi.eventTriggered.add(handleEventTriggered);// listen for events
			
			super.loaded();
		}
		
		private function setupExampleButtons():void
		{
			var btnClip:MovieClip;
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			btnClip = MovieClip(super._hitContainer).btn1;
			ButtonCreator.createButtonEntity( btnClip, this, standardPopup );
			ButtonCreator.addLabel( btnClip, "Popup", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			btnClip = MovieClip(super._hitContainer).btn2;
			ButtonCreator.createButtonEntity( btnClip, this, keyboardPopup );
			ButtonCreator.addLabel( btnClip, "Keyboard", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_text = MovieClip(super._hitContainer).textBox.tf as TextField	// simple on/off movieclip to demonstrate example
			_text.text = "";
			
			btnClip = MovieClip(super._hitContainer).btn3;
			ButtonCreator.createButtonEntity( btnClip, this, charDialogWindowPopup );
			ButtonCreator.addLabel( btnClip, "Char Message", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			
			btnClip = MovieClip(super._hitContainer).btn4;
			ButtonCreator.createButtonEntity( btnClip, this, null );
			ButtonCreator.addLabel( btnClip, "Blank", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn5;
			ButtonCreator.createButtonEntity( btnClip, this, Command.create(progressDialogWindow, ProgressBox.STATE_NONE) );
			ButtonCreator.addLabel( btnClip, "Message", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn6;
			ButtonCreator.createButtonEntity( btnClip, this, Command.create(progressDialogWindow, ProgressBox.STATE_WAITING) );
			ButtonCreator.addLabel( btnClip, "Waiting", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn7;
			ButtonCreator.createButtonEntity( btnClip, this, Command.create(progressDialogWindow, ProgressBox.STATE_LOADING) );
			ButtonCreator.addLabel( btnClip, "Loading", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			btnClip = MovieClip(super._hitContainer).btn8;
			ButtonCreator.createButtonEntity( btnClip, this, Command.create(progressDialogWindow, ProgressBox.STATE_COMPLETE) );
			ButtonCreator.addLabel( btnClip, "Complete", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "showPopup")	// trigger from dialogue
			{
				standardPopup();
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////// STANDARD POPUP /////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Creates and opens a uniquely popup class
		 */
		private function standardPopup( button:Entity = null ):void
		{
			var popup:CharacterPopupScreen = super.addChildGroup(new CharacterPopupScreen(super.overlayContainer)) as CharacterPopupScreen;
			popup.id = "characterPopupScreen";
		}
		
		////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////// KEYBOARD /////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Creates and open a KeybaordPopup
		 */
		private function keyboardPopup( button:Entity ):void
		{
			var keyboard:KeyboardPopup = addChildGroup(new KeyboardPopup()) as KeyboardPopup;
			keyboard.config(null,null,true,true,true,false);
			keyboard.groupPrefix = "ui/keyboard/";
			keyboard.keyboardType = KeyboardCreator.KEYBOARD_TEXT;
			keyboard.textFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			keyboard.bufferRatio = .1;
			keyboard.init( overlayContainer );
			
			keyboard.keyInput.add( onKeyInput );
			keyboard.ready.addOnce( onKeyboardLoaded );
			
			// delay creating transitions until assets have loaded, as the transition relies on the asset dimensions for positioning information.
			keyboard.ready.addOnce( Command.create( onKeyboardLoaded, keyboard ) );	
			super.addChildGroup( keyboard);
			
			_text.text = "";
		}
		
		private function onKeyboardLoaded( keyboard:KeyboardPopup ):void
		{
			keyboard.setTransitions();
		}
		
		// pass inputs from keyboard to textdisplay, test input for scene progression
		public function onKeyInput( value:String ):void
		{	
			_text.text += value;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////// CHARACTER DIALOGUE WINDOW /////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Creates and open a CharacterDialogWindow
		 */
		private function charDialogWindowPopup( button:Entity ):void
		{
			if( !_charDialogWindow )
			{
				_charDialogWindow = new CharacterDialogWindow( super.overlayContainer );
				_charDialogWindow.config( null, null, false, false, false, false );
				//		_charDialogWindow.configData( super.groupPrefix + "dialogPopup/", "charWindow.swf" );
				_charDialogWindow.ready.addOnce( Command.create( onCharDialogReady, _charDialogWindow ) );
				super.addChildGroup( _charDialogWindow );
			}
			else	
			{
				playMessage();
			}
		}
		
		private function onCharDialogReady( obj:*, charDialog:CharacterDialogWindow ):void
		{
			var transitionData:TransitionData = new TransitionData();
			var xPos:int = super.shellApi.viewportWidth/2 - charDialog.screen.width/2;
			transitionData.init( xPos, -charDialog.screen.height, xPos, 20, Strong.easeOut );
			charDialog.transitionIn = transitionData;
			charDialog.transitionOut = transitionData.duplicateSwitch( Strong.easeOut );
			
			// adjust character
			charDialog.adjustChar( "drHare", charDialog.screen, new Point( charDialog.screen.width * .12, charDialog.screen.height * .43), .5 );
			
			// assign textfield
			charDialog.textField = TextUtils.refreshText( charDialog.screen.content.tf );
			charDialog.textField.embedFonts = true;
			charDialog.textField.defaultTextFormat = new TextFormat("CreativeBlock BB", 18, 0x000000);
			
			_dialogIndex = 0;
			playMessage();
		}
		
		private function playMessage():void
		{
			if( !_charDialogWindow.isOpened )
			{
				_charDialogWindow.messageComplete.addOnce(onMessageComplete);
				_charDialogWindow.playMessage( _dialogIds[_dialogIndex], true, true );
				
				_dialogIndex++;
				if( _dialogIndex == _dialogIds.length )
				{
					_dialogIndex = 0;
				}
			}
		}
		
		
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////// CHARACTER DIALOGUE WINDOW /////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Creates and open a ProgressDialogWindow
		 */
		private function progressDialogWindow( button:Entity = null, state:String = "none"):void
		{
			_progressWindow = new ProgressBox( super.overlayContainer );
			_progressWindow.setup( state, "Window title", "Helpful descriptive message", true, true );
			super.addChildGroup( _progressWindow );
			
			setupProgressState(state);
		}
		
		private function setupProgressState( state = ProgressBox.STATE_COMPLETE):void
		{
			switch(state)
			{
				case ProgressBox.STATE_WAITING:
					SceneUtil.delay( _progressWindow, 4, Command.create(onComplete, ProgressBox.STATE_LOADING) );
					break;
				case ProgressBox.STATE_LOADING:
					_progressPercent = 0;
					SceneUtil.addTimedEvent( _progressWindow, new TimedEvent( .2, 0, updateProgress ) );
					break;
				default:
					break;
			}
		}
		
		private function onComplete( nextState = ProgressBox.STATE_COMPLETE):void
		{
			_progressWindow.setState( nextState );
			setupProgressState( nextState );
		}
		
		private function updateProgress():void
		{
			if( _progressPercent >= 1)
			{
				onComplete();
				return
			}
			_progressPercent += .05;
			_progressWindow.progressPercent = _progressPercent;
		}
		
		private function onMessageComplete():void
		{
			trace("message has completed");
		}
		
		private var _text:TextField;
		private var _progressPercent:Number;
		
		private var _progressWindow:ProgressBox;
		private var _charDialogWindow:CharacterDialogWindow;
		private var _dialogIds:Vector.<String> = new <String>["firstMessage", "secondMessage", "thirdMessage", "fourthMessage"];
		private var _dialogIndex:int = 0;
	}
}

