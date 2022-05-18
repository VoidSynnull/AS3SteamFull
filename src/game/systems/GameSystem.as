package game.systems
{
	import ash.tools.ListIteratingSystem;
	import ash.core.Node;
	import game.util.EntityUtils;
	
	public class GameSystem extends ListIteratingSystem
	{
		public function GameSystem(nodeClass:Class, nodeUpdateFunction:Function, nodeAddedFunction:Function = null, nodeRemovedFunction:Function = null):void
		{
			super(nodeClass, nodeUpdateFunction, nodeAddedFunction, nodeRemovedFunction);
		}
						
		override public function update(time:Number):void
		{
			for( var node:Node = super.nodeList.head; node; node = node.next )
			{
				if (!EntityUtils.sleeping(node.entity))
				{
					nodeUpdateFunction(node, time);
				}
			}
		}
	}
}