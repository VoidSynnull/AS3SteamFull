package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	import flash.text.TextField;
	
	import game.components.ui.CardItem;
	import game.data.profile.ProfileData;
	import game.data.text.TextStyleData;
	import game.util.TextUtils;
	
	public class CreditsContentView extends CardContentView
	{
		public function CreditsContentView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			this.shellApi.profileManager.active.creditsChanged.remove(this.creditsChanged);
			super.destroy();
		}
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			_textField = new TextField();
			_textField = TextUtils.refreshText(_textField);
			TextUtils.applyStyle(shellApi.textManager.getStyleData(TextStyleData.CARD, "credits"),_textField);			
			groupContainer.addChild(_textField);
			_textField.selectable = false;
			_textField.wordWrap = false;
			_textField.multiline = false;
			_textField.width = 180;
			_textField.height = 50;
			
			this.creditsChanged(this.shellApi.profileManager.active);
			this.shellApi.profileManager.active.creditsChanged.add(this.creditsChanged);
		}
		
		private function creditsChanged(profileData:ProfileData, previousCredits:Number = NaN):void
		{	
			_textField.text = shellApi.profileManager.active.credits.toString();
		}
		
		private var _textField:TextField;
	}
}