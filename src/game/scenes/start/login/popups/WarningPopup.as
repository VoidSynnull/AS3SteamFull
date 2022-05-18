package game.scenes.start.login.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	
	import game.ui.popup.Popup;
	import game.util.TextUtils;
	
	public class WarningPopup extends Popup
	{
		private var title:String;
		private var text:String;
		private var tfTitle:TextField;
		private var tfText:TextField;
		private var content:MovieClip;
		
		private const FONT:String = "CreativeBlock BB";
		
		public function WarningPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/start/login/";
			super.screenAsset = "warning.swf";
			
			super.darkenBackground = true;
			super.pauseParent = false;
			super.init(container);
			load();
		}
		
		public function ConfigPopup(title:String, text:String):void
		{
			if(title)
				this.title = title;
			if(text)
				this.text = text;
		}
		
		override public function loaded():void
		{
			preparePopup();
			centerPopupToDevice();
			
			content = screen.warning;
			content.x = -content.width/2;
			content.y = -content.height/2;
			
			content.addEventListener(KeyboardEvent.KEY_DOWN, pressAnyButtonToClose);
			content.focusRect = false;
			content.stage.focus = content;
			
			tfTitle = content["title"];
			if(title)
				tfTitle.text = title;
			tfTitle = TextUtils.refreshText(tfTitle,FONT);
			
			tfText = content["text"];
			if(text)
				tfText.text = text;
			tfText = TextUtils.refreshText(tfText, FONT);
			
			loadCloseButton("",50,50,false,content);
			
			super.loaded();
		}
		
		private function pressAnyButtonToClose(event:KeyboardEvent):void
		{
			content.removeEventListener(KeyboardEvent.KEY_DOWN, pressAnyButtonToClose);
			super.close();
		}
	}
}