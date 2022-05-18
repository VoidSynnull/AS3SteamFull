package game.scenes.myth.sphinx.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class BridgeComponent extends Component
	{
		public var isDown:Boolean = false;
		public var isOn:Boolean = false;
		
		public var displayEntity:Entity;
		public var pathEntity:Entity;
		
		public var fallRotation:Number;
		public var reboundOne:Number; 
		public var reboundTwo:Number;
		
		public var pathIn:WaterWayComponent;
		public var feedsInto:WaterWayComponent;
	}
}