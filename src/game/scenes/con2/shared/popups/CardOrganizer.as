package game.scenes.con2.shared.popups
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class CardOrganizer extends Component
	{
		public function CardOrganizer(id:String, originalIndex:Number, originalPos:Point, isDeckCard:Boolean = true)
		{
			this.id = id;
			index = originalIndex;
			pos = originalPos;
			deckCard = isDeckCard;
		}
		
		public var id:String;
		public var index:Number;
		public var pos:Point;
		public var deckCard:Boolean;
	}
}