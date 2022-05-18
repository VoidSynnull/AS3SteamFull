package game.systems.motion
{
	import ash.core.Engine;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.PositionSmoothingNode;
	import game.systems.GameSystem;

	public class PositionSmoothingSystem extends GameSystem
	{
		public function PositionSmoothingSystem()
		{
			super(PositionSmoothingNode, updateNode, nodeAdded);
		}
		
		private function nodeAdded(node:PositionSmoothingNode):void
		{
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;
			
			motion._x = motion.previousX = spatial.x;
			motion._y = motion.previousY = spatial.y;
			motion._rotation = motion.previousRotation = spatial.rotation;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(PositionSmoothingNode);
			
			super.removeFromEngine(systemManager);
		}
		
		/**
		 *  interpolate between current physics position and old one for smooth movement between fixed physics updates.
		 */
		private function updateNode(node:PositionSmoothingNode, time:Number):void
		{
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;

			if(!motion.smoothPosition || !super.systemManager.fixedTimestepUpdates)
			{
				spatial._x = motion.x;
				spatial._y = motion.y;
				spatial._rotation = motion.rotation;
				spatial._invalidate = true;
				return;
			}
			
			if(spatial._updateX) 
			{ 
				motion.previousX = motion._x = spatial.x; 
				spatial._updateX = false; 
			}
			else if(motion.x != motion.previousX)
			{ 
				spatial._x = smoothValue(motion.x, motion.previousX);
				spatial._invalidate = true;
			}
			else if(motion._updateX)
			{
				spatial._x = motion.x;
				spatial._invalidate = true;
				motion._updateX = false;
			}
			
			if(spatial._updateY) 
			{ 
				motion.previousY = motion._y = spatial.y; 
				spatial._updateY = false; 
			}
			else if(motion.y != motion.previousY)
			{ 
				spatial._y = smoothValue(motion.y, motion.previousY);
				spatial._invalidate = true;
			}
			else if(motion._updateY)
			{
				spatial._y = motion.y;
				motion._updateY = false;
				spatial._invalidate = true;
			}
			
			if(spatial._updateRotation) 
			{ 
				motion.previousRotation = motion._rotation = spatial.rotation; 
				spatial._updateRotation = false; 
			}
			else if(motion.rotation != motion.previousRotation)
			{ 
				spatial._rotation = smoothValue(motion.rotation, motion.previousRotation); 
				spatial._invalidate = true;
			}
			else if(motion._updateRotation)
			{
				spatial._rotation = motion.rotation;
				motion._updateRotation = false;
				spatial._invalidate = true;
			}
		}
		
		/**
		 * This interpolates between a previous and current value of a spatial property based on the amount of time since the last update.
		 */
		private function smoothValue(current:Number, previous:Number):Number
		{
			var ratio:Number = super.systemManager.fixedTimestepAccumulatorRatio[FixedTimestep.MOTION_LINK];
			
			if(isNaN(ratio)) { ratio = 0; }
			
			const oneMinusRatio:Number = 1.0 - ratio;
			
			if(isNaN(previous)) 
			{ 
				return(current); 
			}
			
			return(ratio * current + (oneMinusRatio * previous));
		}
	}
}