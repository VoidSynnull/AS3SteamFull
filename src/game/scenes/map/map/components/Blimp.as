package game.scenes.map.map.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	
	public class Blimp extends Component
	{
		public var target:Spatial;
		
		public var isRight:Boolean = true;
		
		public var shape:Entity;
		public var timeline:Timeline;
		public var spatial:Spatial;
		
		public function Blimp(target:Spatial, shape:Entity)
		{
			this.target = target;
			
			this.shape 		= shape;
			this.timeline 	= shape.get(Timeline);
			this.spatial 	= shape.get(Spatial);
		}
	}
}