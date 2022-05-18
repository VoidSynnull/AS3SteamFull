package game.scenes.virusHunter.shipDemo.systems 
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	import flash.display.Sprite;
	import game.systems.SystemPriorities;

	import game.scenes.virusHunter.shipDemo.components.Current;
	import game.scenes.virusHunter.shipDemo.nodes.CurrentNode;
	
	public class CurrentSystem extends System
	{
		public function CurrentSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_nodes = systemsManager.getNodeList( CurrentNode );
		}
		
		override public function update( time:Number ):void
		{
			var node:CurrentNode;
			var current:Current;
			var display:Sprite;
			var pointX:Number;
			var pointY:Number; 
			
			for ( node = _nodes.head; node; node = node.next )
			{
				display = Sprite( node.display.displayObject );
				current = node.current;
				if( current )
				{
					if (current.baseY < -current.maxHeight) 
					{
						current.baseY = 0;
						current.curWidth = current.minWidth;
						//_x = startX;
					}
					current.baseY -= current.hStep;
					current.curWidth += current.wStep;
					current.space = current.curWidth / current.segments;
					
					//_x -= wStep/2;
	//				Sprite( display.displayObject )
					display.graphics.clear();
					display.graphics.lineStyle( current.thickness, current.color, Math.random()*100 );
					var offset:int = 0;//maxOffset/(1 + Math.abs(mid));
					pointX = -current.curWidth / 2;
					pointY = current.baseY + Math.random() * offset - offset / 2;
					display.graphics.moveTo( pointX, pointY );
					for (var i:int = -current.segments / 2; i <= current.segments / 2; i++) 
					{
						offset = 4 * current.maxOffset / (1 + Math.abs(current.mid + Math.abs(i)));
						pointX = current.space * i;
						pointY = current.baseY + Math.random() * offset - offset / 2;
						display.graphics.lineTo( pointX, pointY );
					}	
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( CurrentNode );
			_nodes = null;
		}
		
		private var _nodes : NodeList;
	}
}