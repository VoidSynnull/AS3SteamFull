package game.scenes.mocktropica.mountain.systems
{
	import flash.display.DisplayObjectContainer;
	import engine.components.Spatial;
	
//	import game.scenes.mocktropica.mountain.components.MancalaBeadComponent;
	import game.scenes.mocktropica.mountain.components.MancalaBugComponent;
//	import game.scenes.mocktropica.mountain.nodes.MancalaBeadNode;
	import game.scenes.mocktropica.mountain.nodes.MancalaBugNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	public class MancalaSystem extends GameSystem
	{
		public function MancalaSystem()
		{
			super( MancalaBugNode, updateNode );
		}
		
		public function updateNode( bugNode:MancalaBugNode, time:Number ):void
		{
//			var beadNode:MancalaBeadNode;
			var bug:MancalaBugComponent = bugNode.bug;
			var displayObject:DisplayObjectContainer;
			
			
			switch( bug.state )
			{
				case bug.HIDE:
					bugNode.display.visible = false;
					bug.state = bug.HIDDEN;
					break;
				
				case bug.SEEK:
					bug.target.x = bug.start.x + ( Math.random() * 60 ) - 30;
					bug.target.y = bug.start.y + ( Math.random() * 60 ) - 30;
					bug.state = bug.MOVE;
					break;
				
				case bug.MOVE:					
					bugShuffle( bugNode );
					break;
				
				case bug.FLY:
					bugShuffle( bugNode, true );
					break;
				
				case bug.PANIC:
					bugNode.timeline.gotoAndPlay( "openWings" );
					bug.target.x = ( Math.random() * 100 ) + 800;
					bug.target.y = ( Math.random() * 100 ) + 700;
					
					if( Math.random() < .5 )
					{
						bug.target.x *= -1;
					}
					
					if( Math.random() < .5 )
					{
						bug.target.y *= -1;
					}
					bug.state = bug.FLY;
					break;
			}
		}
		
		private function bugShuffle( bugNode:MancalaBugNode, flying:Boolean = false ):void
		{
			var bug:MancalaBugComponent = bugNode.bug;
			
			var dx:Number = bug.target.x - bugNode.spatial.x;
			var dy:Number = bug.target.y - bugNode.spatial.y;
			var angle:Number = Math.atan2( dy, dx );
			var modifier:Number = bug.crawlSpeed;
			
			if( flying )
			{
				modifier = bug.flySpeed;
			}
			
			bugNode.motion.velocity.x = Math.cos( angle ) * modifier;
			bugNode.motion.velocity.y = Math.sin( angle ) * modifier;
			
			var degrees:Number = angle * ( 180 / Math.PI );
			var delta:Number = bugNode.spatial.rotation - degrees;
			
			if ( delta < -180 )
			{
				bugNode.spatial.rotation = bugNode.spatial.rotation + 360;
				delta += 360;
			}
			if ( delta >= 180 )
			{
				bugNode.spatial.rotation = bugNode.spatial.rotation - 360;
				delta -= 360;
			}
			
			if( Math.abs( delta ) < .2 )
			{
				bugNode.spatial.rotation = degrees;
			}
			else
			{
				bugNode.spatial.rotation = bugNode.spatial.rotation - delta * .1;
			}
			
			var targetDistance:Number = GeomUtils.spatialDistance( bugNode.spatial, new Spatial( bug.target.x, bug.target.y ));
			if( targetDistance <= 5 )
			{
				bug.state = bug.SEEK;
				
				if( flying )
				{
					bug.state = bug.HIDE;
				}
			}
		}
	}
}