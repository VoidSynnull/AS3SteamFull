package game.ui.elements
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.ui.photo.Photo;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	
	import org.osflash.signals.Signal;
	
	public class DualTextDialogPicturePopup extends Popup
	{
		private const PREFIX:String = "ui/popups/";
		private const ASSET:String = "dualTextDialogPicturePopup.swf";
		private const SOUND:String = "ui_button_click.mp3";
		private const TEXT_FONT:String = "CreativeBlock BB";
		private const FONT_SCALE:Number = .55;
		private const MAX_FONT_SIZE:int = 25;
		
		public var photo:Photo;
		
		public var buttonClicked:Signal;
		public var photoPrepared:Signal;
		
		private var _content:MovieClip;
		private var _display:DisplayObjectContainer;
		protected var _button1:Entity;
		protected var _button2:Entity;
		private var _gotoMap:Boolean;
		private var _twoButtons:Boolean;
		private var _dialog1Text:String;
		private var _dialog2Text:String;
		private var _button1Text:String;
		private var _button2Text:String;
		
		private var _photoAsset:String;
		private var _photoPrefix:String;
		
		protected var _confirmed:Boolean;
		
		public function DualTextDialogPicturePopup(container:DisplayObjectContainer=null, gotoMap:Boolean = false, twoButtons:Boolean = false)
		{
			_gotoMap = gotoMap;
			_twoButtons = twoButtons;
			buttonClicked = new Signal(Boolean);
			photoPrepared = new Signal(DualTextDialogPicturePopup);
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.transitionIn = new TransitionData();
			this.transitionIn.duration = 0.3;
			this.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			this.transitionOut = this.transitionIn.duplicateSwitch();
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= false;
			this.groupPrefix = PREFIX;
			this.screenAsset = ASSET;
			
			super.load();
		}
		
		public function configData(asset:String, prefix:String):void
		{
			_photoPrefix = prefix;
			_photoAsset = asset;
		}
		
		override public function loaded():void
		{
			super.preparePopup();
			
			SceneUtil.lockInput( this , false);
			
			_content = screen["content"];
			
			layout.centerUI(_content);
			
			// set up buttons
			
			var clip:MovieClip = _content["confirmButton"];
			
			if(!_twoButtons)
				clip.x = _content.width / 2;
			
			_button1 = ButtonCreator.createButtonEntity(clip, this, onConfirmClicked); 
			
			clip = _content["cancelButton"];
			
			if(!_twoButtons)
				_content.removeChild(clip);
			else
				_button2 = ButtonCreator.createButtonEntity(clip, this, onCancelClicked);
			
			// set up text
			
			_display = _content["display"];
			
			updateText(_dialog1Text, _dialog2Text, _button1Text, _button2Text);
			
			// set up snapShot to be ready to place an image inside the container
			
			clip = _display["image"]["container"];
			photo = new Photo(clip);
			photo.configData(_photoAsset, _photoPrefix);
			photo.ready.addOnce(photoReady);
			addChildGroup(photo);
		}
		
		public function photoReady( ...args ):void
		{
			photoPrepared.dispatch(this);
			
			if(photoPrepared.numListeners == 0)
				bitmap();
		}
		
		public function onCharLoaded(char:Entity, allCharactersLoaded:Boolean):void
		{
			if(allCharactersLoaded)
			{
				bitmapDisplay();
			}
		}
		
		public function bitmapDisplay():void
		{
			// characters need time to be positioned
			SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, bitmap) ).countByUpdate = true;
		}
		
		private function bitmap():void
		{
			super.convertToBitmapSprite(_display);
			open(groupReady);
		}
		
		// updates the contents of text fields and gives them appropriate font sizes for amount of text
		
		public function updateText(dialog1Text:String = null, dialog2Text:String = null, buttonText:String = null, secondButtonText:String = null):void
		{
			var tf:TextField;
			if(dialog1Text != null)
			{
				_dialog1Text = dialog1Text;
				if(_content != null)
				{
					tf = TextField(_display["tf1"]);
					formatText(tf, _dialog1Text, 3);
				}
			}
			
			if(dialog2Text != null)
			{
				_dialog2Text = dialog2Text;
				if(_content != null)
				{
					tf = TextField(_display["tf2"]);
					formatText(tf, _dialog2Text, 1);
				}
			}
			
			if(buttonText != null)
			{
				_button1Text = buttonText;
				if(_button1 != null)
				{
					tf = TextField(EntityUtils.getDisplayObject(_button1)["buttonText"]);
					formatText(tf, _button1Text);
				}
			}
			
			if(_twoButtons && secondButtonText != null)
			{
				_button2Text = secondButtonText;
				if(_button2 != null)
				{
					tf = TextField(EntityUtils.getDisplayObject(_button2)["buttonText"]);
					formatText(tf, _button2Text);
				}
			}
		}
		
		private function formatText(tf:TextField, text:String, lines:int = 1):void
		{
			tf = TextUtils.refreshText(tf, TEXT_FONT);
			var format:TextFormat = new TextFormat( TEXT_FONT, MAX_FONT_SIZE, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER );
			var fontSize:Number = (tf.width * lines) / (text.length * FONT_SCALE);
			var sizeValue:Number = Math.min(MAX_FONT_SIZE, fontSize);
			format.size = sizeValue;
			
			tf.wordWrap = true;
			tf.setTextFormat(format);
			tf.defaultTextFormat = format;
			tf.text = text;
			
			if( lines > 1 )
			{
				tf.y += sizeValue * ( lines - tf.numLines );
			}
		}
		
		public function onCancelClicked(entity:Entity):void
		{
			pressButton( false );
		}
		
		public function onConfirmClicked(entity:Entity):void
		{
			pressButton( true );
		}
		
		private function pressButton(confirm:Boolean):void
		{
			_confirmed = confirm;
			close( false, transitionComplete );
			buttonClicked.dispatch(confirm);
			AudioUtils.play(parent, SoundManager.EFFECTS_PATH + SOUND);
		}
		
		public function transitionComplete():void
		{
			if(_gotoMap && _confirmed)
				shellApi.loadScene(shellApi.sceneManager.gameData.mapClass);
			else
				shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			remove();
		}
	}
}