package game.scenes.prison.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import game.components.ui.CardItem;
	import game.ui.card.CardContentView;
	import game.util.DataUtils;
	
	public class GumContentView extends CardContentView
	{
		public function GumContentView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			var gumAmount:String = DataUtils.getString(shellApi.getUserField("prisonGum", shellApi.island));
			if(!gumAmount)
				gumAmount = "0";
			
			var textContainer:Sprite = new Sprite();
			groupContainer.addChild(textContainer);
			
			var textfield:TextField = new TextField();
			var textformat:TextFormat = new TextFormat("Billy Serif", 24, 0x000000);
			textfield.defaultTextFormat = textformat;			
			textfield.autoSize = TextFieldAutoSize.CENTER;			
			textfield.wordWrap = false;
			textfield.embedFonts = true;
			textfield.mouseEnabled = false;
			textfield.multiline = false;
			textfield.text = gumAmount;
			textfield.text += Number(gumAmount) != 1 ? " Sticks" : " Stick";
			textfield.x = -textfield.width*.5;
			textfield.y = 90;
			
			textContainer.addChild(textfield);
			if(onComplete)
				onComplete();
		}
	}
}