package game.data.ui
{
	import game.data.display.SpatialData;

	public class GestureState
	{
		public var spatialData:SpatialData;
		public var state:String;
		public function GestureState(state:String = UP, spatialData:SpatialData = null)
		{
			this.state = state;
			if(spatialData == null)
				spatialData = new SpatialData();
			this.spatialData = spatialData;
		}
		
		public static const UP:String = "up";
		public static const DOWN:String = "down";
	}
}