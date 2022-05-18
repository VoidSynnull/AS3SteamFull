package game.scenes.virusHunter.backRoom.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class PaperPieces extends Component
	{
		public var bpPieces:Vector.<Entity> = new Vector.<Entity>; // blueprint piece entities
		public var pdPieces:Vector.<Entity> = new Vector.<Entity>; // pizza delivery piece entities
		public var psPieces:Vector.<Entity> = new Vector.<Entity>; // pizza script piece entities
	}
}