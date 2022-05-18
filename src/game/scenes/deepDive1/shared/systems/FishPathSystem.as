package game.scenes.deepDive1.shared.systems
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.scenes.deepDive1.shared.components.FishPath;
	import game.scenes.deepDive1.shared.data.FishPathData;
	import game.scenes.deepDive1.shared.nodes.FishPathNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	
	public class FishPathSystem extends GameSystem
	{
		public function FishPathSystem()
		{
			super(FishPathNode, nodeUpdate, nodeAdded, nodeRemoved);
		}
		
		public function nodeUpdate(node:FishPathNode, time:Number):void
		{
			var fishEnt:Entity = node.entity;
			var path:FishPath = node.path;
			var data:FishPathData = path.getCurrentData();
			if( !path.reachedPath )	// if we haven't reached a path yet, continue to update
			{
				if(data.swimStyle.update(node, time))
				{
					path.pathTargetReached.dispatch(fishEnt);
	
					if( path.nextIndex != path.currentIndex )
					{
						path.currentIndex = path.nextIndex;
						path.reachedPath = false;
					}
					else
					{
						path.reachedPath = true;
						defaultState(node);
					}
				}
			}
		}		
		
		private function defaultState(node:FishPathNode):void
		{
			node.timeline.gotoAndPlay(node.path.movingLabel);
		}
		
		public function nodeAdded(node:FishPathNode):void
		{
			var fishEnt:Entity = node.entity;
			var path:FishPath = node.path;
			var data:FishPathData = path.data[path.currentIndex];
			var target:Point = data.targetPosition;
			
			EntityUtils.position(fishEnt,target.x,target.y);
			node.spatial.rotation = data.rotation;
			data.swimStyle.update(node, 0);
		}		
		
		public function nodeRemoved(node:FishPathNode):void
		{
			
		}		
	}
}