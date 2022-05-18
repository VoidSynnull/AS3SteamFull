package game.scenes.con2.shared.cardGame.systems.CardSlotSystem
{
	import flash.display.DisplayObject;
	import flash.text.TextField;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class CardSlot extends Component
	{
		public var card:Entity;
		public var highLight:Boolean;
		public var display:DisplayObject;	// used as highlight
		public var text:TextField;
		public var highLightValue:Number;
		public var highLightSpeed:Number;
		public var maxHihgLight:Number;
		
		public function CardSlot(display:DisplayObject = null, highLightSpeed:Number = 1, maxHighLight:Number = 1)
		{
			highLightValue = 0;
			highLight = false;
			this.highLightSpeed = highLightSpeed;
			this.display = display;
			this.maxHihgLight = maxHighLight;
		}
		
		public function get isEmpty():Boolean {return card == null;}
		
		public static function canSwapCards(from:CardSlot, to:CardSlot, fromCanBeEmpty:Boolean = false):Boolean
		{
			if(!from.isEmpty || fromCanBeEmpty)
				return true
			else
				return false;
		}
		
		public static function swapCards(from:CardSlot, to:CardSlot):void
		{
			var card:Entity = to.card;
			to.card = from.card;
			from.card = card;
		}
	}
}