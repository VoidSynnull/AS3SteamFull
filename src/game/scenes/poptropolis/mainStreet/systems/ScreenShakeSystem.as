package game.scenes.poptropolis.mainStreet.systems
{
	import ash.core.Engine;
	
	import game.scenes.poptropolis.mainStreet.nodes.ScreenShakeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;
	
	/**
	 * NOTE :: The camera is actually now an entity, so we can do this a different way - Bard
	 * 
	 * Because the Camera isn't an Entity and only specifies a target Spatial for it to follow, I can't add a Spatial
	 * Offset for shaking to the Camera for it to be picked up by the Render System. So the workaround is to give the player a
	 * Screen Shake component with a reference to a Spatial that the Camera is also targeting. The target moves with the
	 * player's Spatial, and then gets a "homebrew" offset applied to it. Viola! Screen shaking!
	 */
	public class ScreenShakeSystem extends GameSystem
	{
		public var playAudio:Signal = new Signal(Boolean);
		
		public function ScreenShakeSystem()
		{
			super(ScreenShakeNode, updateNode);
			
			this._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:ScreenShakeNode, time:Number):void
		{
			node.shake.target.x = node.spatial.x;
			node.shake.target.y = node.spatial.y;
			
			if(node.shake.target.y > node.shake.limitY)
				node.shake.target.y = node.shake.limitY;
			
			node.shake.target.y += node.shake.y;
			
			if(node.shake.shaking)
			{
				node.shake.time += node.shake.rate * time;
				node.shake.y = Math.sin(node.shake.time) * node.shake.radius;
				node.shake.y *= node.shake.shakeTime / node.shake.shakeWait;
				
				node.shake.shakeTime -= time;
				if(node.shake.shakeTime <= 0)
				{
					node.shake.shakeTime 	= node.shake.shakeWait;
					node.shake.shaking 		= false;
					
					node.shake.time = 0;
					node.shake.y 	= 0;
					
					this.playAudio.dispatch(false);
				}
			}
			else
			{
				node.shake.pauseTime += time;
				if(node.shake.pauseTime >= node.shake.pauseWait)
				{
					node.shake.pauseTime = 0;
					node.shake.shaking = true;
					
					this.playAudio.dispatch(true);
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			this.playAudio.removeAll();
			
			super.removeFromEngine(systemManager);
		}
	}
}