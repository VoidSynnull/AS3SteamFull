package game.scenes.deepDive2.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.scene.characterDialog.DialogData;
	import game.ui.popup.CharacterDialogWindow;
	import game.util.EntityUtils;
	import game.util.TextUtils;
	
	public class AtlantisMessageWindow extends CharacterDialogWindow
	{
		public function AtlantisMessageWindow(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function loaded():void
		{
			super.loaded();
			_staticImage = this.screen.content.staticOverlay;
			_staticImage.alpha = 0;
			
			_alienImage = EntityUtils.createSpatialEntity(this, screen.content.alien);
			BitmapTimelineCreator.convertToBitmapTimeline(_alienImage, screen.content.alien);
			_alienImage.get(Timeline).gotoAndStop("empty");
			EntityUtils.turnOffSleep(_alienImage);
			
			textField = TextUtils.refreshText(screen.content.tf);
			textField.embedFonts = true;
			textField.wordWrap = true;
			textField.defaultTextFormat = MESSAGE_TEXT;
			
			_textfield2 = TextUtils.refreshText(screen.content.tf2);
			_textfield2.embedFonts = true;
			_textfield2.wordWrap = true;
			_textfield2.defaultTextFormat = MESSAGE_TEXT;
			_textfield2.text = "";
		}
		
		public function playStaticMessage(dialogId:String, openWindow:Boolean = true, closeOnComplete:Boolean = true, removeOnComplete:Boolean = false):void
		{
			_staticImage.alpha = 1;
			this.screen.content.addChild(_staticImage);	
			textField.defaultTextFormat = STATIC_TEXT;
			
			playMessage(dialogId, openWindow, closeOnComplete, removeOnComplete);
			messageComplete.addOnce(staticMessageDone);
		}
		
		public function playAlienMessage(alienId:String, englishId:String, level:int = 0, openWindow:Boolean = true, closeOnComplete:Boolean = true, removeOnComplete:Boolean = false):void
		{
			textField.defaultTextFormat = STATIC_TEXT;
			textField.text = "";
			
			charEntity.get(Display).visible = false;
			_alienImage.get(Timeline).gotoAndPlay("s" + level);
			
			playMessage(alienId, openWindow, closeOnComplete, removeOnComplete);
			messageComplete.addOnce(alienMessageDone);
			_englishId = englishId;			
		}
		
		override protected function showDialog(dialogData:DialogData):void
		{
			if(_englishId != null)
			{
				var dialog:Dialog = charEntity.get(Dialog);
				var data:DialogData = dialog.getDialog(_englishId);
				_textfield2.htmlText = data.dialog;
				_textfield2.defaultTextFormat = MESSAGE_TEXT;
			}
			
			super.showDialog(dialogData);
		}
		
		override protected function closeMessage():void
		{
			_textfield2.htmlText = "";
			super.closeMessage();
		}
		
		private function staticMessageDone():void
		{
			_staticImage.alpha = 0;
			textField.defaultTextFormat = MESSAGE_TEXT;
		}
		
		private function alienMessageDone():void
		{
			_textfield2.htmlText = "";
			_englishId = null;
			charEntity.get(Display).visible = true;
			_alienImage.get(Timeline).gotoAndStop("empty");
			textField.defaultTextFormat = MESSAGE_TEXT;
		}
		
		private var _staticImage:MovieClip;
		private var _alienImage:Entity;
		private var _textfield2:TextField;
		private var _englishId:String;
		private const MESSAGE_TEXT:TextFormat = new TextFormat( "Futura", 16, 0x47FFD5, true, false, null, null, null, "left", null, 10, null, 0 );
		private const STATIC_TEXT:TextFormat = new TextFormat("Modern Destronic", 16, 0x47FFD5, true, false, null, null, null, "left", null, 10, null, 0);
	}
}