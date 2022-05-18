package game.systems.entity
{
	import engine.components.Spatial;
	
	import game.components.entity.character.part.Joint;
	import game.data.animation.entity.PartAnimationData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.JointAnimationNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	/**
	 * Positions a joint from the PartAnimationData that has been assigned to.
	 * Applied to each joint entity.
	 * NOTE :: Functionality for reorienting clips orientation point is not same as center is disabled
	 */
	public class JointAnimationSystem extends GameSystem
	{
		public function JointAnimationSystem()
		{
			super( JointAnimationNode, updateNode );
			super._defaultPriority = SystemPriorities.animate;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
			super.onlyApplyLastUpdateOnCatchup = true;
		}
			
		/**
		 * Calls for spatial to update on each frame advance
		 * @param	node
		 */
		private function updateNode(node:JointAnimationNode, time:Number):void
		{
			if ( node.timeline.frameAdvance && node.joint.partAnimData )
			{
				if(!node.joint.ignoreRig)
					updateSpatial( node )
			}
		}
	
		/**
		 * Positions joint spatial based on PartAnimationData for corresponding frame
		 * @param	node
		 */
		private function updateSpatial( node:JointAnimationNode ):void
		{	
			var spatial:Spatial = node.spatial;
			var joint:Joint = node.joint;
			var animation:PartAnimationData =  joint.partAnimData;
			var frameIndex:int = node.timeline.currentIndex;
		
			/*
			if ( !joint.isSet )	//called once when a new animation is loaded
			{ 
				//setTransformPnt( node, animation ); // TODO :: this got broken during the conversion into Entity
			}
			*/
			
			if( frameIndex <= 0 )	//there is no keyframe data at frame 0, so positions part to the 1st frame of the animation.
			{ 
				spatial.x 			= animation.x;
				spatial.y 			= animation.y;
				if( !joint.ignoreRotation )	{ spatial.rotation 	= animation.rotation; } 
			}
			else
			{
				spatial.x 			= animation.x + Number( animation.kframes[frameIndex].x );
				spatial.y 			= animation.y + Number( animation.kframes[frameIndex].y );
				if( !joint.ignoreRotation )	{ spatial.rotation = animation.rotation + Number( animation.kframes[frameIndex].rotation );} 
				// TODO : currently scale is not accounted for, but this can be added if necessary
			}

		}
		
		// TODO :: this got broken during the conversion into Entity, best if it just doesn't happen as it can be expensive.
		/**
		 * Accounts for the possibility that the Transformation Point in the animation may be different than the coordinate point of the original clip
		 */
		/*
		private function setTransformPnt( node:jointAnimationNode, animation:PartAnimationData ):void
		{	
			var container:MovieClip = node.display.displayObject as MovieClip;
			
			//get current regPnts of clip
			var bounds:Rectangle = container.getBounds( container.parent );
			var currentRegX:Number 	= container.x - bounds.left;
			var currentRegY:Number 	= container.y - bounds.top;

			var newX:Number = animation.transformPoint.x * animation.dimensions.width;
			var newY:Number = animation.transformPoint.y * animation.dimensions.height;

			var xOffset:Number = newX - currentRegX;
			var yOffset:Number = newY - currentRegY;

			node.joint.initX = Number( animation.x + xOffset );
			node.joint.initY = Number( animation.y + yOffset );
			
			
			//shift all the children the same amount,
			//but in the opposite direction
			for (var i:int = 0; i < container.numChildren; i++) 
			{
				container.getChildAt(i).x -= xOffset;
				container.getChildAt(i).y -= yOffset;
			}
			
			node.joint.isSet = true;
		}
		*/
	}
}
