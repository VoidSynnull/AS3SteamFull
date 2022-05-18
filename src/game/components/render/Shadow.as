package game.components.render
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	
	public class Shadow extends Component
	{
		public var quality:Number;
		// base values
		public var offSetX:Number;
		public var offSetY:Number;
		
		public var minAlpha:Number;//how faded shadow can get when median is 0
		public var maxAlpha:Number;//how dark shadow can get when median is 1
		
		public var scaleGrowth:Number;// how much bigger the shadow can get
		
		public var median:Number;
		//z depth ratio of where the shadow's source is, in reference to the light source.
		//1 would be as if object is against the shadow's surface
		//0 would be as if object is covering the light source
		
		//components for the shadow created
		public var shadow:Entity;
		public var source:FollowTarget;
		public var display:Display;
		public var spatial:Spatial;
		
		public function Shadow()
		{
			offSetX = offSetY = 0;
			minAlpha = median = scaleGrowth = .25;
			maxAlpha = .75;
			quality = 1;
		}
	}
}