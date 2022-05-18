package game.scenes.con2.shared.cardGame
{
	import flash.display.Sprite;
	
	import ash.core.Component;

	public class CCGCard extends Component
	{
		public var value:uint;
		public var effect:String;
		public var id:String;
		
		public var faceUp:Boolean;
		public var frontDisplay:Sprite;
		public var backDisplay:Sprite;
		
		public function CCGCard(id:String, value:uint = 1, effect:String = "none")
		{
			this.id = id;//stored item id
			this.value = value;// card's value
			this.effect = effect; // card's effect
			faceUp = false;
		}
		
		override public function destroy():void
		{
			effect = id = null;
			frontDisplay = backDisplay = null;
		}
	}
}