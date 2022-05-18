package game.creators.ui
{
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.ui.GridControlScrollable;
	import game.components.ui.GridSlot;
	import game.components.ui.Ratio;
	import game.managers.EntityPool;
	import game.components.entity.EntityPoolComponent;
	import game.systems.ui.GridScrollingSystem;
	import game.systems.ui.GridSlotSystem;
	import game.util.GeomUtils;

	public class GridScrollableCreator
	{
		public function GridScrollableCreator()
		{
		}
		
		public function create( frameRect:Rectangle, itemRect:Rectangle, cols:int, rows:int, group:Group = null, slotBuffer:Number = 10, isHorizontal:Boolean = true, shiftHandler:Function = null, frameBuffer:Number = 0, id:String = "gridControl"):Entity
		{
			var gridEntity:Entity = new Entity()
				
			// create scrollable grid for cards
			var gridControl:GridControlScrollable = new GridControlScrollable();
			
			// setup frame 
			gridControl.frameRect = frameRect;
			gridControl.isHorizontal = isHorizontal;
			if( frameBuffer > 0 )
			{
				if( isHorizontal )
				{
					gridControl.frameRect.x = frameBuffer;
					gridControl.frameRect.width -= frameBuffer * 2;
				}
				else
				{
					gridControl.frameRect.y = frameBuffer;
					gridControl.frameRect.height -= frameBuffer * 2;
				}
			}
			gridControl.rows = rows;
			gridControl.columns = cols;
			
			// setup slots
			gridControl.slotBuffer = slotBuffer;
			gridControl.slotRect = GeomUtils.getLayoutCellRect( gridControl.frameRect, itemRect, cols, rows, slotBuffer);	// dimension of card slot in a single row layout, want to fit at least 3 cards on screen at once 
			
			var pool:EntityPool = new EntityPool();
			var poolComponent:EntityPoolComponent = new EntityPoolComponent(pool);

			if( shiftHandler != null )
			{
				gridControl.didScroll.add(shiftHandler);			// listen for updates in position TODO :: Want to get rid of this type of communication
			}
			
			gridEntity.add(poolComponent)
			gridEntity.add(new Id(id))
			gridEntity.add( gridControl )
			gridEntity.add( new Ratio() );
			gridEntity.name = id;
			
			if( group != null )
			{
				group.addEntity(gridEntity);
				group.addSystem( new GridScrollingSystem() );
				group.addSystem( new GridSlotSystem() );
			}
			
			return gridEntity;
		}
		
		/**
		 * Add an Entity to grid.
		 * Entity is added to an entity pool and given necessary components.
		 * @param gridEntity
		 * @param slotEntity
		 * @param bounds
		 * @param slotActivatedHandler
		 * @param slotDeactivatedHandler
		 * @return 
		 * 
		 */
		public function addSlotEntity( gridEntity:Entity, slotEntity:Entity, bounds:Rectangle, slotActivatedHandler:Function = null, slotDeactivatedHandler:Function = null ):Entity
		{
			var poolComponent:EntityPoolComponent = gridEntity.get( EntityPoolComponent );
			if( poolComponent == null )
			{
				poolComponent = new EntityPoolComponent(new EntityPool());
				gridEntity.add( poolComponent );
			}
			var pool:EntityPool = poolComponent.pool;
			
			var gridSlot:GridSlot = slotEntity.get( GridSlot )
			if( !gridSlot )
			{
				gridSlot = new GridSlot();
				slotEntity.add( gridSlot );
			}

			if( slotActivatedHandler != null)
			{
				gridSlot.onActivated.add(slotActivatedHandler);
			}
			if( slotDeactivatedHandler != null)
			{
				gridSlot.onDeactivated.add(slotDeactivatedHandler);
			}
			
			var edge:Edge = new Edge();
			edge.unscaled = bounds;
			slotEntity.add( edge );

			slotEntity.add( new Sleep( true, true ) );
			// TODO? :: add GridControl to slotEntity?
			
			pool.release( slotEntity, INACTIVE );
			
			return slotEntity;
		}
		
		public static const ACTIVE:String = "active";
		public static const INACTIVE:String = "inactive";
	}

}