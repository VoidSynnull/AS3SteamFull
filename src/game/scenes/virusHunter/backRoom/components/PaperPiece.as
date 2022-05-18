package game.scenes.virusHunter.backRoom.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class PaperPiece extends Component
	{
		
		public function PaperPiece($id:int, $type:int){
			id = $id;
			type = $type;
		}
		
		public var down:Boolean = false; // if mouse/touch is down
		public var up:Boolean = true; // if mouse/touch is up - probably not needed
		
		public var offsetX:Number; // mouse/touch offset of X
		public var offsetY:Number; // mouse/touch offset of Y
		
		public var id:int; // id from left to right 1-n
		public var type:int; // blueprint(1), pizza delivery(2), pizza script(3)
		public var joinedLeft:Entity; // piece entity that is joined to the left
		public var joinedRight:Entity; // piece entity that is joined to the right
	}
}