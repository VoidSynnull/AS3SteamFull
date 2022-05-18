package game.scenes.myth.grove.systems
{
	import ash.core.Engine;
	
	import game.scenes.myth.grove.components.LavaComponent;
	import game.scenes.myth.grove.nodes.LavaNode;
	import game.systems.GameSystem;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class LavaSystem extends GameSystem
	{
		public function LavaSystem()
		{
			super( LavaNode, updateNode );
		}
		
		private function updateNode( node:LavaNode, time:Number ):void
		{
			var lava:LavaComponent = node.lava;
			lava.pilar.height = ( 1738 - lava.platformSpatial.y );
			if( lava.position )
			{
				lava.position.zone = new RectangleZone( -40, -lava.pilar.height, 40, 0 );
			}
		}
		
		override public function addToEngine( engine:Engine ):void
		{			
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( engine:Engine ):void
		{
			engine.releaseNodeList( LavaNode );
			
			super.removeFromEngine( systemManager );
		}
	}
}