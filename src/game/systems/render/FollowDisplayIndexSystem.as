package game.systems.render
{
	import flash.display.DisplayObjectContainer;
	
	import game.nodes.render.FollowDisplayIndexNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class FollowDisplayIndexSystem extends GameSystem
	{
		public function FollowDisplayIndexSystem()
		{
			super(FollowDisplayIndexNode, updateNode);
			this._defaultPriority = SystemPriorities.postRender;
		}
		
		private function updateNode(node:FollowDisplayIndexNode, time:Number):void
		{
			//Do we have a leader DisplayObject to follow?
			if(node.follow.leader)
			{
				//Does the leader have a parent?
				var parentLeader:DisplayObjectContainer = node.follow.leader.parent;
				if(parentLeader)
				{
					//If the following DisplayObject does not have the same parent, make it so!
					if(node.display.displayObject.parent != parentLeader)
					{
						parentLeader.addChild(node.display.displayObject);
					}
					
					//Get the leader's index.
					var index:int = parentLeader.getChildIndex(node.follow.leader);
					
					//Offset by how far behind/in front we wanna be.
					index += node.follow.indexOffset;
					
					//Protect against going out of the parent's index bounds.
					if(index < 0)
					{
						index = 0;
					}
					else if(index > parentLeader.numChildren - 1)
					{
						index = parentLeader.numChildren - 1;
					}
					
					parentLeader.setChildIndex(node.display.displayObject, index);
				}
			}
		}
	}
}