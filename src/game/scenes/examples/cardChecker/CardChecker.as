package game.scenes.examples.cardChecker
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ui.CardGroup;
	import game.util.TextUtils;
	
	public class CardChecker extends PlatformerGameScene
	{
		public function CardChecker()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/cardChecker/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			setupExampleButtons();
			
			super.loaded();
		}
		
		private function setupExampleButtons():void
		{
			var btnClip:MovieClip;
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			btnClip = MovieClip(super._hitContainer).range_btn;
			ButtonCreator.createButtonEntity( btnClip, this, getRangeStoreCards );
			ButtonCreator.addLabel( btnClip, "Get Cards", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			btnClip = MovieClip(super._hitContainer).single_btn;
			ButtonCreator.createButtonEntity( btnClip, this, getStoreCard );
			ButtonCreator.addLabel( btnClip, "Get Card", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			_cardIdTF 	= MovieClip(super._hitContainer).cardId as TextField	// simple on/off movieclip to demonstrate example
			_cardMinTF 	= MovieClip(super._hitContainer).cardMinRange as TextField	// simple on/off movieclip to demonstrate example
			_cardMaxTF 	= MovieClip(super._hitContainer).cardMaxRange as TextField	// simple on/off movieclip to demonstrate example
				
			labelFormat.color = 0x000000;

			_cardIdTF = TextUtils.convertText( _cardIdTF, labelFormat, String(MIN_DEAFULT) );
			_cardMinTF = TextUtils.convertText( _cardMinTF, labelFormat, String(MIN_DEAFULT) );
			_cardMaxTF = TextUtils.convertText( _cardMaxTF, labelFormat, String(MAX_DEFAULT) );
			_cardIdTF.type = TextFieldType.INPUT;
			_cardMinTF.type = TextFieldType.INPUT;
			_cardMaxTF.type = TextFieldType.INPUT;
		}

		private function getRangeStoreCards( button:Entity ):void
		{
			//get store cards
			var i:int = Number(_cardMaxTF.text);
			var start:int = Number(_cardMinTF.text);
			for (i; i >= start; i--) 
			{
				shellApi.getItem( String(i), CardGroup.STORE );
			}
		}
		
		private function getStoreCard( button:Entity ):void
		{
			shellApi.getItem( _cardIdTF.text, CardGroup.STORE );
		}

		private const MIN_DEAFULT:int = 3000;
		private const MAX_DEFAULT:int = 3360;
		
		private var _cardType:String = CardGroup.STORE;
		
		private var _cardIdTF:TextField;
		private var _cardMinTF:TextField;
		private var _cardMaxTF:TextField;
	}
}