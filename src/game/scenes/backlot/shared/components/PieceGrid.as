package game.scenes.backlot.shared.components
{
	import ash.core.Component;
	
	public class PieceGrid extends Component
	{
		// for each , within the first layer of [] is vertical starting from the top
		// for each , with in the second layer of [] is horizontal starting from the left
		
		// example: [[1,0], [1,1], [1,0]]; = a side ways t where the t points to the right
		
		// 1 0
		// 1 1
		// 1 0
		
		// |
		// ----
		// |
		
		// visuall looks like this sort of
		
		// the first nest of [] is [1,0] this is the right side of the t if it were upright
		// the second nest of [] is [1,1] this is the tail of the t if it were upright
		// the third nest of [] is [1,0] this is the left side of the t if it were upright
		
		private const squareGrid:Array = [[1,1],[1,1]];
		
		private const verticalLineGrid:Array = [[1],[1],[1],[1]];
		private const horizontalLineGrid:Array = [[1,1,1,1]];
		
		private const normalTGrid:Array = [[1,1,1],[0,1,0]];
		private const upsideDownTGrid:Array = [[0,1,0],[1,1,1]];
		private const rightTGrid:Array = [[1,0], [1, 1], [1, 0]];
		private const leftTGrid:Array = [[0,1], [1, 1], [0, 1]];
		
		private const normalLGrid:Array = [[1,0],[1,0],[1,1]];
		private const normalLGridUpsideDown:Array = [[1,1],[0,1],[0,1]];
		private const normalLGridRotatedLeft:Array = [[0,0,1],[1,1,1]];
		private const normalLGridRotatedRight:Array =[[1,1,1],[1,0,0]];
		
		private const backwardsLGrid:Array = [[0,1],[0,1],[1,1]];
		private const backwardsLGridUpsideDown:Array = [[1,1],[1,0],[1,0]];
		private const backwardsLGridRotatedLeft:Array =[[1,1,1],[0,0,1]];
		private const backwardsLGridRotatedRight:Array =[[1,0,0],[1,1,1]];
		
		private const normalZGrid:Array = [[1,1,0],[0,1,1]];
		private const verticalZGrid:Array = [[0, 1], [1, 1], [1, 0]];
		
		private const normalSGrid:Array = [[0,1,1],[1,1,0]];
		private const verticalSGrid:Array = [[1, 0], [1, 1], [0, 1]];
		
		public var grid:Array;
		
		public var startX:Number;
		public var startY:Number;
		public var depth:int;
		
		public var onGrid:Boolean;
		
		public var pointX:int;
		public var pointY:int;
		
		public function PieceGrid(pieceType:String):void
		{
			switch(pieceType)
			{
				case "square":
				{
					grid = squareGrid;
					break;
				}
				case "verticalLine":
				{
					grid = verticalLineGrid;
					break;
				}
				case "horizontalLine":
				{
					grid = horizontalLineGrid;
					break;
				}
				case "normalT":
				{
					grid = normalTGrid;
					break;
				}
				case "upsideDownT":
				{
					grid = upsideDownTGrid;
					break;
				}
				case "rightT":
				{
					grid = rightTGrid;
					break;
				}
				case "leftT":
				{
					grid = leftTGrid;
					break;
				}
				case "normalL":
				{
					grid = normalLGrid;
					break;
				}
				case "normalLUpsideDown":
				{
					grid = normalLGridUpsideDown;
					break;
				}
				case "normalLRotatedRight":
				{
					grid = normalLGridRotatedRight;
					break;
				}
				case "normalLRotatedLeft":
				{
					grid = normalLGridRotatedLeft;
					break;
				}
				case "backwardsL":
				{
					grid = backwardsLGrid;
					break;
				}
				case "backwardsLUpsideDown":
				{
					grid = backwardsLGridUpsideDown;
					break;
				}
				case "backwardsLRotatedRight":
				{
					grid = backwardsLGridRotatedRight;
					break;
				}
				case "backwardsLRotatedLeft":
				{
					grid = backwardsLGridRotatedLeft;
					break;
				}
				case "normalZ":
				{
					grid = normalZGrid;
					break;
				}
				case "verticalZ":
				{
					grid = verticalZGrid;
					break;
				}
				case "normalS":
				{
					grid = normalSGrid;
					break;
				}
				case "verticalS":
				{
					grid = verticalSGrid;
					break;
				}
			}
		}
	}
}