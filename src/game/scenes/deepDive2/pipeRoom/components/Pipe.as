package game.scenes.deepDive2.pipeRoom.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Pipe extends Component
	{
		public static var TYPE_BAR:String = "bar";
		public static var TYPE_ANGLE:String = "angle";
		public static var TYPE_START:String = "start";
		public static var TYPE_END:String = "end";
		
		// index: 0 = up, 1 = right, 2 = down, 3 = left
		public var rotation:int = 0;
		
		public var type:String;
		
		public var upNeighbor:Entity;
		public var rightNeighbor:Entity;
		public var downNeighbor:Entity;
		public var leftNeighbor:Entity;
		
		public var up:Boolean = false;
		public var right:Boolean = false;
		public var down:Boolean = false;
		public var left:Boolean = false;
		
		public var endPiece:Boolean = false;
		public var rotationUpdated:Boolean = false;
		public var exitDirection:int = 0;
		
		public function Pipe(initalRotation:int, possibleLinks:Array, type:String)
		{
			this.rotation = initalRotation;
			
			this.upNeighbor = possibleLinks[0];
			this.rightNeighbor = possibleLinks[1];
			this.downNeighbor = possibleLinks[2];
			this.leftNeighbor = possibleLinks[3];
			
			this.type = type;
			
			super();
		}
		
		// advance rotation forward, should never go backwards and loops after 3
		public function rotatePipeTick():void
		{
			rotationUpdated = true;
			rotation += 1;
			if(rotation > 3){
				rotation = 0;
			}
		}		
		
		
	};
};
