/**
 * Follow a spatial component.
 * Directly modifies an entity's spatial to follow a target.
 */

package game.systems.motion
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Spatial;
	
	import game.nodes.motion.FollowTargetNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.Utils;

	public class FollowTargetSystem extends GameSystem
	{
		private var _nodes : NodeList;

		public function FollowTargetSystem()
		{
			super(FollowTargetNode, updateNode, nodeAdded);
			super._defaultPriority = SystemPriorities.move;
		}
		
		private function nodeAdded(node:FollowTargetNode):void
		{			
			if(node.followTarget.properties == null)
			{
				node.followTarget.properties = new Vector.<String>;
				node.followTarget.properties.push(PROPERTY_X);
				node.followTarget.properties.push(PROPERTY_Y);
			}
		}
		
		private function updateNode(node:FollowTargetNode, time:Number):void
		{
			var follower:Spatial = node.follower;
			var leader:Spatial = node.followTarget.target;
			var delta:Number;
			var property:String;
			var offset:Point = node.followTarget.offset;
			var offsetValue:Number;
			var leaderProperty:*;
			var rate:Number = Utils.getVariableTimeEase(node.followTarget.rate, time);
			
			// if has Draggable component, only update if dragging is true.
			if( node.draggable )
			{
				if( !node.draggable._active )
				{
					return;
				}
			}
			
			for(var n:uint = 0; n < node.followTarget.properties.length; n++)
			{
				property = node.followTarget.properties[n];
				
				if(follower[property] != null && leader[property] != null)
				{
					offsetValue = 0;
					
					leaderProperty = leader[property];
					
					// check for x & y offset
					if ( offset || node.followTarget.applyCameraOffset)
					{
						var edgeValue:Number = 0;
						var rotation:Number = -leader.rotation * Math.PI / 180;
						if ( property == PROPERTY_X )
						{
							if (offset) 
							{ 
								if(node.followTarget.accountForRotation)
									offsetValue = offset.x * Math.cos(rotation) + offset.y * Math.sin(rotation); 
								else
									offsetValue = offset.x;
							}
							if(node.followTarget.applyCameraOffset && _shellApi.camera != null) 
							{ 
								leaderProperty /= _shellApi.camera.scale;
								offsetValue += -_shellApi.camera.x - _shellApi.viewportWidth * (.5 / _shellApi.camera.scale);
							}
							if(node.followTarget.allowXFlip){
								if(leader.scaleX < 0){
									offsetValue *= 1;
								}
								else{
									offsetValue *= -1;
								}
							}
							
							if(node.bounds != null)
							{
								if(node.edge != null)
									edgeValue = node.edge.rectangle.right;
								if(leaderProperty + offsetValue + edgeValue > node.bounds.box.right)
									offsetValue = node.bounds.box.right -leaderProperty - edgeValue;
								if(node.edge != null)
									edgeValue = node.edge.rectangle.left;
								if(leaderProperty + offsetValue + edgeValue < node.bounds.box.left)
									offsetValue = node.bounds.box.left - leaderProperty - edgeValue;
							}
						}
						if ( property == PROPERTY_Y )
						{
							if (offset) 
							{ 
								if(node.followTarget.accountForRotation)
									offsetValue = offset.y * Math.cos(rotation) - offset.x * Math.sin(rotation); 
								else
									offsetValue = offset.y;
							}
							if(node.followTarget.applyCameraOffset && _shellApi.camera != null) 
							{ 
								leaderProperty /= _shellApi.camera.scale;
								offsetValue += -_shellApi.camera.y - _shellApi.viewportHeight * (.5 / _shellApi.camera.scale);
							}
							
							if(node.bounds != null)
							{
								if(node.edge != null)
									edgeValue = node.edge.rectangle.bottom;
								if(leaderProperty + offsetValue + edgeValue > node.bounds.box.bottom)
									offsetValue = node.bounds.box.bottom - leaderProperty - edgeValue;
								if(node.edge != null)
									edgeValue = node.edge.rectangle.top;
								if(leaderProperty + offsetValue + edgeValue < node.bounds.box.top)
									offsetValue = node.bounds.box.top - leaderProperty - edgeValue;
							}
						}
						if(property == PROPERTY_ROTATION)
						{
							offsetValue = node.followTarget.rotationOffSet;
						}
					}
					
					if(node.followTarget.rate == 1)
					{
						follower[property] = leaderProperty + offsetValue;
					}
					else
					{
						delta = ( leaderProperty + offsetValue ) - follower[property];
						
						if (Math.abs(delta) > rate)
						{
							follower[property] += delta * rate;
							reachedTarget( node, false );
						}
						else
						{
							follower[property] = leaderProperty + offsetValue;
							reachedTarget( node, true );
						}
					}
				}
			}
		}
		
		private function reachedTarget( node:FollowTargetNode, targetReached:Boolean ):void
		{
			if ( node.followTarget.isTargetReached != targetReached )
			{
				node.followTarget.isTargetReached = targetReached;
				if ( node.followTarget.reachSignal.numListeners > 0 && targetReached )
				{
					node.followTarget.reachSignal.dispatch();
				}
			}
		}
					
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList( FollowTargetNode );
			super.removeFromEngine(systemManager);
		}

		private const PROPERTY_X:String = "x";
		private const PROPERTY_Y:String = "y";
		private const PROPERTY_ROTATION:String = "rotation";
		[Inject]
		public var _shellApi:ShellApi;
	}
}
