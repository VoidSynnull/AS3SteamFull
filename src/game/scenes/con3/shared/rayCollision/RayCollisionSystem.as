package game.scenes.con3.shared.rayCollision
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class RayCollisionSystem extends GameSystem
	{
		public function RayCollisionSystem()
		{
			super(RayCollisionNode, updateNode, nodeAdded, nodeRemoved);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			this._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		private function updateNode(node:RayCollisionNode, time:Number):void
		{
			//If the RayCollision maxLength is not in sync with the Ray maxLength, then redraw it.
			this.resizeCollisionLine(node);
			
			//Draw the visible ray length to the length of the collision.
			//Collision length will change based on other systems.
			node.render.length = node.rayCollision._length;
			
			//Set the collision length back to the ray length for the next iteration of collision distance checks.
			node.rayCollision._length = node.rayCollision._rayLength;
		}
		
		private function resizeCollisionLine(node:RayCollisionNode):void
		{
			if(node.rayCollision._rayLength != node.ray.length)
			{
				node.rayCollision._rayLength = node.ray.length;
				node.rayCollision._bitmap.width = node.rayCollision._rayLength;
			}
		}
		
		private function nodeAdded(node:RayCollisionNode):void
		{
			node.display.displayObject.addChild(node.rayCollision._bitmap);
			
			//Only draw the collision shape once, then resize its width if/when the ray length changes.
			var bitmapData:BitmapData = new BitmapData(5, 5, false, 0);
			node.rayCollision._bitmap.bitmapData = bitmapData;
			node.rayCollision._bitmap.y = -2.5;
			node.rayCollision._bitmap.visible = false;
			
			this.resizeCollisionLine(node);
		}
		
		private function nodeRemoved(node:RayCollisionNode):void
		{
			node.display.displayObject.removeChild(node.rayCollision._bitmap);
			node.rayCollision._bitmap.bitmapData.dispose();
		}
	}
}