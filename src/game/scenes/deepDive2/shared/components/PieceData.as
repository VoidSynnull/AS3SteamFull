package game.scenes.deepDive2.shared.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class PieceData extends Component
	{
		public var startingPos:Point;
		public var snapRadius:Number = 40;
		
		public function PieceData(x:Number = 0, y:Number = 0, snapRadius:Number = 40)
		{
			this.startingPos = new Point(x,y);
			this.snapRadius = snapRadius;
		}
	}
}

