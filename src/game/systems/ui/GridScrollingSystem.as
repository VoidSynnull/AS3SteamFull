package game.systems.ui
{
	import ash.core.Entity;
	
	import engine.components.OwningGroup;
	
	import game.components.entity.Sleep;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.GridSlot;
	import game.components.ui.Ratio;
	import game.components.ui.ScrollBox;
	import game.creators.ui.GridScrollableCreator;
	import game.data.ui.RectSlot;
	import game.managers.EntityPool;
	import game.nodes.ui.GridControlScrollNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.Utils;

	public class GridScrollingSystem extends GameSystem
	{
		public function GridScrollingSystem() 
		{
			super( GridControlScrollNode, updateNode );
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		private function updateNode( node:GridControlScrollNode, time:Number ):void 
		{
			var grid:GridControlScrollable = node.grid;
			
			if( grid.resetSlots )
			{
				grid.resetSlots = false;

				if( node.entityPool )
				{
					var pool:EntityPool = node.entityPool.pool;
					var slotEntity:Entity;
					var gridSlot:GridSlot;
					var inactiveCards:Vector.<Entity> = pool.getPool( GridScrollableCreator.INACTIVE );
					
					if(inactiveCards == null)
						return;
					var i:uint = 0;
					for (i = 0; i < inactiveCards.length; i++)
					{
						slotEntity = inactiveCards[i];
						gridSlot = slotEntity.get( GridSlot )
						gridSlot.deactivate = true;
						gridSlot.resize = true;
						gridSlot.invalidate = true;
					}
					
					do
					{
						slotEntity = pool.transfer( GridScrollableCreator.ACTIVE, GridScrollableCreator.INACTIVE );
						if( slotEntity != null )
						{
							gridSlot = slotEntity.get( GridSlot )
							gridSlot.deactivate = true;
							gridSlot.resize = true;
							gridSlot.invalidate = true;
						}
					}
					while( slotEntity != null )
				}
			}
			
			if( !grid.lock || grid.refreshPositions )
			{ 
				var ratio:Ratio = node.ratio;
				
				// check fro scroll box // TODO :: would like this handled elsewhere...
				var scrollBox:ScrollBox = node.scrollBox;
				if( scrollBox )
				{
					if( scrollBox.velocity != 0 )
					{
						ratio.decimal +=  Utils.toDecimal(scrollBox.velocity, 0, grid.totalLength);
					}
				}
				
				if( ratio.decimal != grid.currentPercent )
				{
					grid.delta = (grid.currentPercent - ratio.decimal) * grid.totalLength;
					grid.shiftSlots(grid.delta);
					//tableau.velocity = -shift * time;
					grid.currentPercent = ratio.decimal;

					if( node.entityPool )
					{
						updateSlots( node, node.entityPool.pool );
					}
					
					grid.refreshPositions = false;
					grid.didScroll.dispatch();
				}
				else if ( grid.refreshPositions )
				{
					grid.currentPercent = ratio.decimal;
					
					if( node.entityPool )
					{
						updateSlots( node, node.entityPool.pool );
					}
					
					grid.refreshPositions = false;
					grid.didScroll.dispatch();
				}
			}
		}
		
		/**
		 * Update associated Entities (these should have a GridSlot component)
		 */
		private function updateSlots( node:GridControlScrollNode, pool:EntityPool ):void 
		{
			var grid:GridControlScrollable = node.grid;
			var visibleRects:Vector.<RectSlot> = grid.visibleSlots;
			var activeSlots:Vector.<Entity> = pool.getPool( GridScrollableCreator.ACTIVE );
			var slotEntity:Entity;
			var gridSlot:GridSlot;
			var index:int;
			var i:int = 0;
			var j:int = 0;
			var id:String;
			
			if( activeSlots != null )
			{
				// check if currently active slots remain visible
				for ( i= activeSlots.length - 1; i > -1; i--) 		
				{
					var done:Boolean = false;
					
					slotEntity = activeSlots[i];
					gridSlot = slotEntity.get(GridSlot);

					for ( j=0; j< visibleRects.length; j++)
					{
						if( visibleRects[j].index == gridSlot.index)
						{
							gridSlot.reposition = true;
							gridSlot.invalidate = true;
							visibleRects.splice( j, 1 ); // accounted for, remove from list of visible rects
							
							done = true;
							break;
						}
					}
					
					// if no longer visible make inactive
					if(!done)
					{
						gridSlot.deactivate = true;
						gridSlot.invalidate = true;
						pool.transfer( GridScrollableCreator.ACTIVE, GridScrollableCreator.INACTIVE, slotEntity )
					}
				}
			}
			
			// for remaining visible slots, make new slots
			var rectSlot:RectSlot;
			for (i=0; i<visibleRects.length; i++) 
			{
				slotEntity = pool.request( GridScrollableCreator.INACTIVE );
				if( slotEntity )
				{
					pool.release( slotEntity, GridScrollableCreator.ACTIVE );
					gridSlot = slotEntity.get(GridSlot);
					rectSlot = visibleRects[i];
					gridSlot.slotRect = rectSlot.rect;
					gridSlot.index = rectSlot.index;
					gridSlot.activate = true;
					gridSlot.invalidate = true;
					
					// NOTE :: Not wild about this, necessary for Inventory. - bard
					var owningGroup:OwningGroup = slotEntity.get(OwningGroup);
					if( owningGroup )
					{
						owningGroup.group.unpause();
					}
					Sleep(slotEntity.get(Sleep)).sleeping = false;
					slotEntity.sleeping = false;
				}
				else
				{
					trace ("Error :: GridScrollingSystem :: updateSlots : no more available GridSlots" );
					return;
				}
			}
		}

	}
}