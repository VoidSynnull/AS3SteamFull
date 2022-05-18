package game.scenes.myth.sphinx.components
{
	import ash.core.Component;
	
	public class LeverComponent extends Component
	{
		public function LeverComponent( _startLeft:Boolean, _leftIsAlt:Boolean )
		{
			startLeft = _startLeft;
			isLeft = startLeft;
			leftIsAlt = _leftIsAlt;
		}
		
		public var startLeft:Boolean = true;
		public var isLeft:Boolean = true;
		public var leftIsAlt:Boolean = true;
		
		public var altPathOut:WaterWayComponent;
		public var pathIn:WaterWayComponent;
		public var pathOut:WaterWayComponent;
		
	//	public var fall:Entity = new Entity();
	}
}