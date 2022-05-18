package game.scenes.myth.sphinx.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.Emitter;
	
	import org.flintparticles.common.counters.Counter;
	
	public class WaterWayComponent extends Component
	{
		public var isOn:Boolean = false;
		public var foamOn:Boolean = false;
		public var isFall:Boolean = false;
		public var feedsInto:WaterWayComponent;
		
		public var emitterCounter:Counter;
		public var emitter:Emitter;
//		public var foam:Entity = new Entity();
	}
}