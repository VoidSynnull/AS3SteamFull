package game.scenes.time.mali2.components
{	
	import ash.core.Component;
	
	public class PuzzlePiece extends Component
	{
		
		public function PuzzlePiece( columnId:int, rowId:int )
		{
			this.columnId = columnId;
			this.rowId = rowId;
		}
		
		public var columnId:int; // id from left to right 1-n
		public var rowId:int; // id from top to bottom 1-n

		public var connected:Boolean = false;
		public var joinedLeft:Boolean = false; // piece entity that is joined to the left
		public var joinedRight:Boolean = false; // piece entity that is joined to the right
		public var joinedTop:Boolean = false; // piece entity that is joined to the top
		public var joinedBottom:Boolean = false; // piece entity that is joined to the bottom
	}
}