package game.scenes.survival5.sawmill.systems
{
	import engine.components.Spatial;
	
	import game.scenes.survival5.sawmill.nodes.SpinRoundNode;
	import game.systems.GameSystem;
	
	public class SpinRoundSystem extends GameSystem
	{
		public function SpinRoundSystem()
		{
			super(SpinRoundNode, update);
		}
		
		private function update(node:SpinRoundNode, time:Number):void
		{
			var spinSpatial:Spatial = node.spatial;
			var targetSpatial:Spatial = node.spinRound.target.get(Spatial);
			var radius:Number = node.spinRound.radius;			
			var radians:Number = targetSpatial.rotation * DEGRAD;
			
			radians += node.spinRound.offset * DEGRAD;
			spinSpatial.x = targetSpatial.x + radius * Math.cos(radians);
			spinSpatial.y = targetSpatial.y + radius * Math.sin(radians);
		}
		
		private const DEGRAD:Number = Math.PI / 180;
	}
}