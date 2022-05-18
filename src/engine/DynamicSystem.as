package engine
{
	import ash.core.Node;
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	public class DynamicSystem extends System
	{		
		public function DynamicSystem()
		{
			_nodeTypes = new Array();
		}
		
		public function getNodeList(game:Engine, node:Class):NodeList
		{
			_game = game;
			
			var add:Boolean = true;
			
			for (var n:Number = 0; n < _nodeTypes.length; n++)
			{
				if (_nodeTypes[n] == node)
				{
					add = false;
					break;
				}
			}
			
			if (add)
			{
				_nodeTypes.push(node);
			}
			
			return(game.getNodeList( node ));
		}
		
		public function get active():Boolean
		{
			for (var n:Number = 0; n < _nodeTypes.length; n++)
			{
				if (_game.hasNodeList(_nodeTypes[n]))
				{
					return(true);
				}
			}
			
			return(false);
		}
		
		private var _nodeTypes:Array;
		private var _game:Engine;
	}
}