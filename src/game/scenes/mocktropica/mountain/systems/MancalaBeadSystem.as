package game.scenes.mocktropica.mountain.systems
{
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.mountain.components.MancalaBeadComponent;
	import game.scenes.mocktropica.mountain.nodes.MancalaBeadNode;
	import game.systems.GameSystem;
	
	public class MancalaBeadSystem extends GameSystem
	{
		public function MancalaBeadSystem()
		{
			super( MancalaBeadNode, updateNode );
		}
		
		private function updateNode( beadNode:MancalaBeadNode, time:Number ):void
		{
			var bead:MancalaBeadComponent;
			bead = beadNode.bead;
			
			switch( bead.state )
			{
				case bead.SHAKE:
					bead.timer += 75;
					shakeBead( beadNode );
					break;
				case bead.IDLE:
					break;
			}
		}
		
		private function shakeBead( beadNode:MancalaBeadNode ):void
		{
			var beadSpatial:Spatial = beadNode.spatial;
			var bead:MancalaBeadComponent = beadNode.bead;
			
			beadSpatial.x = bead.start.x + bead.magnitude * Math.sin( bead.timer );
			beadSpatial.y = bead.start.y + bead.magnitude * Math.cos( bead.timer );
			beadSpatial.rotation = 10 * bead.magnitude * Math.sin( bead.timer );
			bead.magnitude -= .025;
			
			if( bead.magnitude <= 0 )
			{	
				bead.state = bead.IDLE;
				bead.timer = 0;
			}
		}
	}
}