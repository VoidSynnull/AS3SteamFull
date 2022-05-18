package game.scenes.shrink.bedroomShrunk02.PendulumSystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.nodes.RenderNode;
	
	import org.osflash.signals.Signal;
	
	public class Pendulum extends Component
	{
		public var lastCollision:Entity;
		public var radius:Number;
		public var lasHitTime:Number;
		public var hit:Signal;
		public var renderNode:RenderNode;
		
		public function Pendulum(ball:Entity, radius:Number)
		{
			renderNode = new RenderNode();
			renderNode.entity = ball;
			renderNode.spatial = ball.get(Spatial);
			renderNode.display = ball.get(Display);
			this.radius = radius;
			hit = new Signal();
		}
	}
}