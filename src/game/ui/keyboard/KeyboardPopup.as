package game.ui.keyboard
{	

	import com.greensock.easing.Bounce;
	import com.greensock.easing.Strong;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.KeyboardCreator;
	import game.data.ui.ButtonData;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author Bard
	 * 
	 * Standard keyboard popup
	 */
	
	public class KeyboardPopup extends Popup
	{
		public function KeyboardPopup( container:DisplayObjectContainer = null )
		{	
			keyInput = new Signal();
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			load();
		}
		
		// initiate asset load of group specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.loadFiles(new Array("keyboard.swf"), false, true, loaded);
		}

		// all assets ready
		override public function loaded():void
		{
			super.screen = super.getAsset("keyboard.swf", true) as MovieClip;
			this.fitToDimensions(super.screen);
			
			this.createBitmap(this.screen.content.bg);
			
			createKeys( super.screen );
			
			// TODO :: should be able to use default close button, and just rely on a default position
			//var closeButton:StandardButton = ButtonCreator.createStandardButton( super.screen.content.closeButton.button, handleCloseClicked, null, this );
			super.createCloseButton( super.screen.content.closeButton.button, true );
			//super.createCloseButton()
			
			super.loaded();	//adds screen to container, dispatchs ready
		}
		
		/**
		 * Returns the end transition coordinate for the keyboard to be center horizontal and align along the bottom of the screen
		 * @param openKeyboard - Boolean for whether this method shoudl call open or not
		 * @param offsetY - int amount to offset final y position, varies by keyboard type example : 40 for KEYBOARD_ALL, 80 for KEYBOARD_TEXT
		 */
		public function setTransitions( openKeyboard:Boolean = true, offsetY:int = 40 ):void
		{
			if( screen != null && shellApi != null )
			{
				var xPos:int = shellApi.viewportWidth/2 - ( MovieClip(screen).width/2 / MovieClip(screen).scaleX );
				var yPos:int = shellApi.viewportHeight - ( (MovieClip(screen).height - offsetY) / MovieClip(screen).scaleY );
				var transitionData:TransitionData = new TransitionData();

				transitionData.init( xPos, shellApi.viewportHeight, xPos, yPos, Bounce.easeOut )
				this.transitionIn = transitionData;
				this.transitionOut = transitionData.duplicateSwitch( Strong.easeOut );
				if( openKeyboard )
					super.open();
			}
			trace( "KeyboardPopup :: WARNING :: setTransitions :: calling too early, must be called after loaded" );
		}
		
		/**
		 * Creates keys for keyboard, these are auto-positioned based on the layout Vector.
		 * NOTE :: Eventually would like to handle repositioned keyboards.
		 * @param container
		 */
		private function createKeys( container:DisplayObjectContainer ):void
		{
			// get keyboard layout
			var layout:Vector.<Vector.<ButtonData>> = KeyboardCreator.getLayout( keyboardType );
			
			// create keys
			var i:int;
			var j:int;
			var keyLabel:String;
			for ( i = 0; i <  layout.length; i++ )
			{
				
				for ( j = 0; j <  layout[i].length; j++ )
				{
					var buttonData:ButtonData = layout[i][j];
					buttonData.row = i;
					buttonData.column = j
					super.loadFile( "key.swf", onKeyAssetLoaded, buttonData, layout[i].length );
				}
			}
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
			
			if ( buttonData.labelText != "" )
			{
				// check if a labelContainer is within key
				var labelContainer:DisplayObjectContainer = clip.labelContainer;
				if( !labelContainer )
				{
					labelContainer = clip;
				}
				ButtonCreator.addLabel( labelContainer, buttonData.labelText, textFormat, ButtonCreator.ORIENT_CENTERED );
			}
			
			var buttonEntity:Entity = ButtonCreator.createButtonEntity( clip, this, Command.create(onKeyClicked, buttonData.value), MovieClip(super.screen).content.keyContainer, null, null, true, true );
			Button(buttonEntity.get(Button)).value = buttonData.value;
		}
		
		public function onKeyClicked( buttonEntity:Entity, value:*  ):void
		{
			keyInput.dispatch( value );
		}
		
		override public function close( removeOnClose:Boolean = false, onCloseHandler:Function = null ):void
		{
			shellApi.triggerEvent(CLOSED_KEYBOARD);
			super.close(removeOnClose);
		}
		public const CLOSED_KEYBOARD:String = "closed_keyboard";
		// values are just defaults, should be set prior to init
		public var keyInput:Signal;
		private var _buffer:Number;
		public var bufferRatio:Number = .1;
		public var startY:Number = 0;
		public var textFormat:TextFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
		public var keyboardType:String = KeyboardCreator.KEYBOARD_ALL;
	}
}
