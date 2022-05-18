package game.scenes.deepDive1.shipUnderside
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	public class BackgroundFishSystem extends System
	{
		private var nodes:NodeList
		
		public function BackgroundFishSystem()
		{
			
		}
		
		override public function update( time : Number ) : void
		{
			var sp:Spatial
			var dir:BackgroundFishDir
			var e:Entity
			
			for(var node:BackgroundFishDirNode = nodes.head; node; node = node.next)
			{
				//trace ("..." + e)
				e = node.entity
				dir = node.dir
				sp = Spatial (e.get(Spatial))
				sp.x += dir.direction * dir.speed
				if ((dir.direction > 0 && sp.x > dir.max) || (dir.direction <0 && sp.x < dir.min)) {
					dir.direction *= -1
					Spatial(e.get(Spatial)).scaleX *= -1
				}
			} 
		}
		
		override public function addToEngine(system:Engine):void
		{
			this.nodes = system.getNodeList(BackgroundFishDirNode);
		}
		
		override public function removeFromEngine(system:Engine):void
		{
			system.releaseNodeList(BackgroundFishDirNode);
			this.nodes = null;
		}
	}
}


