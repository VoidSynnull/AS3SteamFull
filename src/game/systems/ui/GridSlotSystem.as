package game.systems.ui
{
	import flash.geom.Rectangle;
	
	import engine.components.Spatial;
	
	import game.components.ui.GridSlot;
	import game.nodes.ui.GridSlotNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class GridSlotSystem extends GameSystem
	{
		public function GridSlotSystem()
		{
			super(GridSlotNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode( node:GridSlotNode, time:Number ):void 
		{
			var slot:GridSlot = node.gridSlot;
			
			// if grid slots' grid control shifted, update grid slot
			if( slot.invalidate )
			{
				slot.invalidate = false;

				if( slot.activate )
				{
					if( slot.resize )
					{
						slot.resize = false;
						var scalePercent:Number = slot.slotRect.width/node.edge.unscaled.width;
						node.spatial.scale 		= scalePercent;
					}
					
					slot.activate = false;
					slot.reposition = false;
					updatePosition( node );
					slot.onActivated.dispatch( node.entity );
				}
				else if( slot.deactivate )
				{
					slot.deactivate = false;
					slot.onDeactivated.dispatch( node.entity );	// allow handlers to determine what needs to happen on deactivation
					//node.sleep.sleeping = true;
				}
				else if( slot.reposition )
				{
					slot.reposition = false;
					updatePosition( node );
				}
			}
		}
		
		/**
		 * Apply Rectangle position to card Entity
		 */
		private function updatePosition( node:GridSlotNode ):void 
		{
			var spatial:Spatial = node.spatial 
			var slot:GridSlot = node.gridSlot;

			var rect:Rectangle = slot.slotRect;
			// Doesn't assume assume center orientation, uses offset
			spatial.x = rect.x + rect.width * slot.offsetXPercent;
			spatial.y = rect.y + rect.height * slot.offsetYPercent;
		}
	}
}