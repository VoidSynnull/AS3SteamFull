package game.systems.motion
{
	import ash.core.Engine;
	
	import engine.components.Spatial;
	
	import game.components.motion.Spring;
	import game.nodes.motion.SpringNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	/**
	 * Positions owning entity towards target using a spring equation.
	 */
	public class SpringSystem extends GameSystem
	{
		public function SpringSystem()
		{
			super( SpringNode, updateNode, nodeAdded );
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = 1/60;
			//super.onlyApplyLastUpdateOnCatchup = true;
		}

		override public function addToEngine(systemsManager:Engine):void
		{
			super.addToEngine(systemManager);
			/*
			for( var node : SpringNode = super.nodeList.head; node; node = node.next )
			{
				nodeAdded( node );
			}
			
			super.nodeList.nodeAdded.add( nodeAdded );
			*/
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(SpringNode);
			
			super.removeFromEngine(systemManager);
		}
		
		/*
		private function nodeAdded(node:SpringNode):void
		{
			node.spatial.previousX = node.spatial.x;
			node.spatial.previousY = node.spatial.y;
			
			if(node.entity.get(Display))
			{
				Display(node.entity.get(Display)).smoothPosition = true;
			}
		}
		
		private function smoothPositions(time:Number):void
		{
			for( var node:SpringNode = super.nodeList.head; node; node = node.next )
			{
				smoothPosition(node, time);
			}
		}
		
		private function smoothPosition(node:SpringNode, time:Number):void
		{
			var spatial:Spatial = node.spatial;
			
			spatial.previousX += (spatial.x - spatial.previousX) * .5;
			spatial.previousY += (spatial.y - spatial.previousY) * .5;
		}
		*/
		private function updateNode( node:SpringNode, time : Number ) : void
		{
			var spatial:Spatial = node.spatial;
			var spring:Spring = node.spring;
				
			var deltaX:Number;
			var deltaY:Number;
			var springForce:Number = spring.spring;
			var dampening:Number = spring.damp;
			
			deltaX = ( ( spring.leader.x + spring.offsetX + spring.offsetXOffset) - spatial.x); 
			deltaY = ( ( spring.leader.y + spring.offsetY + spring.offsetYOffset) - spatial.y);
			
			if ( Math.abs(deltaX) < spring.threshold && Math.abs(deltaY) < spring.threshold &&
				Math.abs(spring._velocity.x) < spring.threshold && Math.abs(spring._velocity.y) < spring.threshold)
			{
				
				spatial.x = spring.leader.x + spring.offsetX + spring.offsetXOffset;
				spatial.y = spring.leader.y + spring.offsetY + spring.offsetYOffset;
				
				if(spring.reachedLeader.numListeners > 0)
					spring.reachedLeader.dispatch();
			}
			else
			{
				spring._velocity.x += (deltaX * springForce);
				spring._velocity.y += (deltaY * springForce);
				spring._velocity.x *= dampening;
				spring._velocity.y *= dampening;
				
				spatial.x += spring._velocity.x;
				spatial.y += spring._velocity.y;
				
				// rotate in relation to spring
				if ( spring.rotateByVelocity )
				{
					spatial.rotation = spring._velocity.x * spring.rotateRatio;
				}
				else if ( spring.rotateByLeader )
				{
					spatial.rotation = spring.leader.rotation * spring.rotateRatio;
				}
			}
		}
		
		private function nodeAdded(node:SpringNode):void
		{
			if (node.spring.startPositioned)
			{
				node.spatial.x = node.spring.leader.x + node.spring.offsetX + node.spring.offsetXOffset;
				node.spatial.y = node.spring.leader.y + node.spring.offsetY + node.spring.offsetYOffset;
				
				if (node.spring.rotateByLeader)
					node.spatial.rotation = node.spring.leader.rotation;
			}
		}
	}
}
