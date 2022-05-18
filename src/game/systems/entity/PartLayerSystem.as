package game.systems.entity
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	
	import game.components.entity.character.part.PartLayer;
	import game.nodes.entity.PartLayerNode;
	import game.systems.SystemPriorities;
	import game.util.DataUtils;
	
	/**
	 * Manages the relaying of parts within a character, 
	 * allowing the 'z depth' of parts to be rearranged dynamically
	 */
	public class PartLayerSystem extends ListIteratingSystem
	{
		public function PartLayerSystem()
		{
			super( PartLayerNode, updateNode );
			super._defaultPriority = SystemPriorities.preRender;
		}
		
		/**
		 * Checks for changes in the PartLayer component.
		 * Rearranges display depth based on PartLayer settings.
		 * @param	node
		 */
		private function updateNode( node:PartLayerNode, time:Number ):void
		{
			if ( node.partLayer.invalidate )
			{
				var partLayer:PartLayer = node.partLayer;
				var display:Display = node.display;
				
				var currentLayer:int = getDisplayLayer( display );
				var nextLayer:int = partLayer.layer;
				
				if ( DataUtils.validString( partLayer.insertPartTarget ) )
				{
					var targetPart:Entity = node.rig.getPart( partLayer.insertPartTarget );
					nextLayer = getDisplayLayer( targetPart.get(Display) );

					if ( partLayer.isAbove )
					{
						nextLayer++;
					}
					else
					{	
						nextLayer--;
					}
					
					partLayer.layer = nextLayer;
					partLayer.clearInsert();
				}
				
				if ( currentLayer != nextLayer )
				{
					var container:DisplayObjectContainer = display.displayObject.parent;
					
					if ( nextLayer < 0 )
					{
						nextLayer = 0;
					}
					else if ( nextLayer > container.numChildren )
					{
						nextLayer = container.numChildren;
					}
					
					container.setChildIndex( display.displayObject, nextLayer );
				}
				
				partLayer.layer = nextLayer;
				partLayer.invalidate = false;
			}
		}
		
		private function getDisplayLayer( display:Display ):int
		{
			return display.displayObject.parent.getChildIndex( display.displayObject );
		}
	}
}
