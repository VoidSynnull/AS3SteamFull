package game.scenes.prison.shared.ventPuzzle
{
	public class VentEnding
	{
		public var id:String;
		
		public var event:String;
		
		public var removeEvent:Boolean;
		
		public function VentEnding(id:String, event:String, removeEvent:Boolean = false)
		{
			this.id = id;
			this.event = event;
			this.removeEvent = removeEvent;
		}
	}
}