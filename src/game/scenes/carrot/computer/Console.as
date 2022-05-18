package game.scenes.carrot.computer
{	
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Strong;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	
	import game.components.ui.TextDisplay;
	import game.creators.ui.KeyboardCreator;
	import game.creators.ui.TextDisplayCreator;
	import game.data.TimedEvent;
	import game.data.ui.TransitionData;
	import game.ui.keyboard.KeyboardPopup;
	import game.util.SceneUtil;
	import game.util.StringUtil;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	/**
	 * ...
	 * @author Bard
	 * 
	 * Popup for entering the codes
	 */
	
	public class Console
	{
		public function Console( scene:Scene, screen:MovieClip )
		{		
			_scene = scene;
			_screen = screen;
			complete = new Signal();
			keyPress = new Signal();
			enterPress = new Signal();
			
			init();
		}
		
		private function init( ):void 	
		{
			// listen to screen click
			_screenClicked = InteractionCreator.create( _screen.content.screenArea, InteractionCreator.CLICK );
			_screenClicked.add( onScreenClicked );
			onScreenClicked();	// bring up keyboard automatically
			
			// create textDisplay
			var textFormat:TextFormat = new TextFormat("Foxley", 20, 0x699EAB, false, false, false );
						
			var textArea:MovieClip = _screen.content.textArea;
			_textDisplayEntity = TextDisplayCreator.createInputText( _scene, textArea, ENTER_PASSWORD, textFormat );
			_textDisplay = _textDisplayEntity.get(TextDisplay);
						
			_textDisplay.hasCaret = true;
			_textDisplay.wordWrap = false;
			_textDisplay.delay = 3;
			_textDisplay.lineMax = 8;
			_textDisplay.tf.width = textArea.width * .7;			// TODO :: Need to figure out why sizes are off, and where scale ratio can be found
			_textDisplay.tf.height = textArea.height * .7;
		}

		public function destroy():void 
		{
			complete.removeAll();
			keyPress.removeAll();
			enterPress.removeAll();
			_screenClicked.removeAll();
			_scene.removeEntity( _textDisplayEntity );
		}
		
		// open/create keyboard
		private function onScreenClicked( e:Event = null ):void
		{
			// creat keyboard popup, if not created
			if ( _keyboard == null )
			{
				initKeyboard();
			}
			else if ( !_keyboard.isOpened )
			{
				_keyboard.open();
				// TODO :: Do we want to close the keyboard if you click on the screen?
			}
		}
		
		private function initKeyboard():void
		{			
			// create keybopard, do not pause parent, which in this case is the computer popup
			_keyboard = _scene.addChildGroup( new KeyboardPopup()) as KeyboardPopup;
			_keyboard.config( null, null, false, false, false, false );
			_keyboard.groupPrefix = _scene.groupPrefix + "keyboard/";
			_keyboard.keyboardType = KeyboardCreator.KEYBOARD_TEXT;
			_keyboard.textFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			_keyboard.bufferRatio = .1;
			_keyboard.init( _scene.groupContainer );
			
			_keyboard.keyInput.add( onKeyInput );
			_keyboard.ready.addOnce( onKeyboardLoaded )
		}
		
		private function onKeyboardLoaded( keyboard:KeyboardPopup ):void
		{
			_keyboard.setTransitions( true, 80);
		}
		
		// pass inputs from keyboard to textdisplay, test input for scene progression
		public function onKeyInput( value:String ):void
		{
			// only accept input once textDisplay is finished displaying current queue
			if ( _textDisplay.queue.length == 0 )
			{
				if ( value == KeyboardCreator.COMMAND_ENTER )
				{
					enterPress.dispatch();
					if ( !_passwordAccepted )
					{
						if ( _inputString == CORRECT_PASSWORD )
						{
							_textDisplay.queue += StringUtil.NEW_LINE + this.PASSWORD_ACCEPTED;
							_textDisplay.queue += StringUtil.NEW_LINE + this.ENTER_COMMAND;
							_passwordAccepted = true;
						}
						else
						{
							_textDisplay.queue += StringUtil.NEW_LINE + this.PASSWORD_DENIED;
							_textDisplay.queue += StringUtil.NEW_LINE + this.ENTER_PASSWORD;
						}
					}
					else
					{
						if ( _inputString == CORRECT_COMMAND )
						{
							_textDisplay.queue += StringUtil.NEW_LINE + this.COMMAND_ACCEPTED;
							_screenClicked.removeAll();	// disable input
							_keyboard.close(true);
							SceneUtil.addTimedEvent( _scene, new TimedEvent( 2, 1, triggerLaunch));	// delay before triggering launch
						}
						else
						{
							_textDisplay.queue += StringUtil.NEW_LINE + this.COMMAND_DENIED;
							_textDisplay.queue += StringUtil.NEW_LINE + this.ENTER_COMMAND;
						}
					}
					
					_inputString = "";
				}
				else if ( value == KeyboardCreator.COMMAND_DELETE )
				{
					if ( _inputString.length > 0 )	// just delete the input, not the command lines
					{
						_inputString = StringUtil.removeLast(_inputString);
						_textDisplay.deleteLine();
					}
					keyPress.dispatch();
				}
				else
				{
					_inputString += value.toLocaleLowerCase();			// store input
					_textDisplay.queue += value.toLocaleLowerCase();	// add to text display queue
					keyPress.dispatch();
				}
			}
		}
		
		private function triggerLaunch():void 
		{
			complete.dispatch();
		}
		
		private var _scene:Scene;
		private var _screen:MovieClip;
		
		public var complete:Signal;
		public var keyPress:Signal;
		public var enterPress:Signal;
		
		private var _screenClicked:NativeSignal;
		private var _keyboard:KeyboardPopup;
		private var _textDisplayEntity:Entity;
		private var _textDisplay:TextDisplay;
		
		private var _inputString:String = "";
		private var _passwordAccepted:Boolean = false;
		
		private var ENTER_PASSWORD:String 		= "enter password> ";
		private var ENTER_COMMAND:String 		= "command> ";
		private var PASSWORD_ACCEPTED:String 	= "...password accepted";
		private var PASSWORD_DENIED:String 		= "...password not recognized";
		private var COMMAND_ACCEPTED:String 	= "...robot control initiated";
		private var COMMAND_DENIED:String 		= "...command not recognized";
		private var CORRECT_PASSWORD:String 	= "fuzzybunny";
		private var CORRECT_COMMAND:String 		= "launch rabbot";
		
	//	private var CORRECT_PASSWORD:String 	= "a";
	//	private var CORRECT_COMMAND:String 		= "b";
	}

}
