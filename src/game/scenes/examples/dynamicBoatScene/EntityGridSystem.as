package game.scenes.examples.dynamicBoatScene
{
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Id;
	
	import game.systems.SystemPriorities;
	
	public class EntityGridSystem extends ListIteratingSystem
	{
		public function EntityGridSystem()
		{
			super(EntityGridElementNode, updateNode);
			
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		/*
		override public function update(time:Number):void
		{
			if(_entityGridNode == null)
			{
				_entityGridNode = _entityGridNodes.head;
			}
			else
			{
				updateGrid(_entityGridNode);
				super.update(time);
			}
		}
		
		private function updateGrid(entityGridNode:EntityGridNode):void
		{
			var entityGrid:EntityGrid = entityGridNode.entityGrid;
			var target:Spatial = _entityGridNode.targetSpatial.target;
			var minX:Number = target.x - entityGrid.drawDistanceX;
			var minY:Number = target.y - entityGrid.drawDistanceY;
			var maxX:Number = target.x + entityGrid.drawDistanceX;
			var maxY:Number = target.y + entityGrid.drawDistanceY;
			
			minX = Math.max(0, minX);
			maxX = Math.min(entityGrid.width, maxX);
			minY = Math.max(0, minY);
			maxY = Math.min(entityGrid.height, maxY);

			var xNodes:Number = maxX - minX;
			var yNodes:Number = maxY - minY;
			var nextGridElement:*;
			
			for (var rows:int = minY; rows <= minY + yNodes; rows++) 
			{			
				for (var columns:int = minX; columns <= minX + xNodes; columns++) 
				{
					nextGridElement = entityGrid.getElement(columns, rows);
					
					if (nextGridElement != null)
					{
						showElement(nextGridElement);
					}
				}	
			}
		}
		
		private function showElement(element:*):void
		{
			if(element is Vector.<EntityGridElement>)
			{
				for each(var elementData:EntityGridElement in element)
				{
					showElement(elementData);
				}
			}
			else
			{
				EntityGridElement(elementData).show = true;
			}
		}
		*/
		private function updateNode(node:EntityGridElementNode, time:Number):void
		{
			var element:EntityGridElement = node.entityGridElement;
			
			// if element's sleep state is equal to its show state, it must be hidden or shown.
			if(element.show == node.sleep.sleeping)
			{
				element.show = !element.show;
				
				trace("show : " + element.show + " : " + node.entity.get(Id).id);
				
				// for now all the setup/teardown rests in the hands of the creator.  Would be nice to have
				//   the ability to do setup/teardown with a generalized creator that works off an xml config.
				if(element.show)
				{
					element.creator.show(node);
				}
				else
				{
					element.creator.hide(node);
				}
			}
		}
		/*
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_entityGridNodes = systemManager.getNodeList(EntityGridNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			super.removeFromEngine(systemManager);
			
			systemManager.releaseNodeList(EntityGridNode);
			systemManager.releaseNodeList(EntityGridElementNode);
			
			_entityGridNode = null;
			_entityGridNodes = null;
		}
		
		private var _entityGridNodes:NodeList;
		private var _entityGridNode:EntityGridNode;
		*/
	}
}