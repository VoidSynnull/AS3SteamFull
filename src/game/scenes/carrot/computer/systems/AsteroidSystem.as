package game.scenes.carrot.computer.systems
{
	
	import flash.display.DisplayObjectContainer;
	import engine.components.Motion;
	import engine.components.Spatial;
	import game.scenes.carrot.computer.components.Asteroid;
	import game.scenes.carrot.computer.nodes.AsteroidNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;

	public class AsteroidSystem extends GameSystem
	{
		public function AsteroidSystem()
		{
			super(AsteroidNode, updateNode);
			super._defaultPriority = SystemPriorities.update;
		}
			     
	    private function updateNode(node:AsteroidNode, time:Number):void
	    {
			var asteroid:Asteroid = node.asteroid;
			
			if ( !asteroid.paused )
			{
				if ( asteroid.waitTime > 0 )
				{
					asteroid.waitTime -= time;
				}
				else if ( !asteroid.active )
				{
					start( node );
				}
				else
				{
					checkCollision( node );
					checkBelowBounds( node );
				}	
			}
		}
		
		private function start(node:AsteroidNode):void
	    {
			var asteroid:Asteroid = node.asteroid;
			
			node.display.visible = true;
			
			node.spatial.x = node.spatial.width * .5 + Math.random() * (asteroid.bounds.width - node.spatial.width)
			node.spatial.y = -node.spatial.height;
			
			node.motion.velocity.y = asteroid.velYMin + Math.random() * asteroid.velYRange;
			asteroid.active = true;
		}
		
		private function checkCollision(node:AsteroidNode):void
	    {
			//check for collision with rabbot
			if (node.display.displayObject.hitTestObject(node.asteroid.target))
			{
				node.asteroid.hitSignal.dispatch();
				reset( node );
				node.asteroid.paused = true;	// needs to be unpaused by scene
			}
		}
		
		private function checkBelowBounds(node:AsteroidNode):void
	    {
			if ( (node.spatial.y - node.spatial.height / 2) > node.asteroid.bounds.height )
			{
				reset(node);
			}
		}
		
		private function reset(node:AsteroidNode):void
	    {
			var asteroid:Asteroid = node.asteroid;
			asteroid.active = false;
			node.display.visible = false;
			node.motion.velocity.y = 0;
			asteroid.waitTime = asteroid.minWaitTime + Math.random() * asteroid.rangeWaitTime;
		}
	}	
}
