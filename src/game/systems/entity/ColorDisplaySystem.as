package game.systems.entity
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import game.components.entity.character.ColorSet;
	import game.data.character.part.ColorAspectData;
	import game.data.character.part.ColorableData;
	import game.data.character.part.InstanceData;
	import game.nodes.entity.ColorDisplayNode;
	import game.systems.SystemPriorities;
	import game.util.ColorUtil;
	import game.util.DataUtils;

	/**
	 * Applies colors to clips.
	 * This system currently used for assigning colors to character parts.
	 */
	public class ColorDisplaySystem extends ListIteratingSystem
	{
		public function ColorDisplaySystem()
		{
			super( ColorDisplayNode, updateNode );
			super._defaultPriority = SystemPriorities.render;
			super.nodeRemovedFunction = CDSNodeRemovedFunction;
		}
				
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(ColorDisplayNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private function CDSNodeRemovedFunction( node:ColorDisplayNode ):void
		{
			if (node.colorSet != null)
			{
				node.colorSet.updateComplete.removeAll();
				node.colorSet.updateComplete = null;
			}
		}
		
		private function updateNode(node:ColorDisplayNode, time:Number):void
		{
			var colorSet:ColorSet = node.colorSet;
	
			if ( colorSet.invalidate )
			{
				if ( node.colorSet.colorAspects.length > 0 )
				{
					// update colors, once all have been updated, update clips
					if ( updateColorAspects( node ) )
					{
						//trace( "Color update part : " + SkinPart(node.entity.get( SkinPart )).id + " 
						if( node.display )
						{
							if( node.display.displayObject )
							{
								updateColorableClips( node, node.display.displayObject );
							}
						}
						colorSet.invalidate = false;
						colorSet.updateComplete.dispatch( node.entity );
					}
				}
				else
				{
					colorSet.invalidate = false;
					colorSet.updateComplete.dispatch( node.entity );
				}
			}
		}
		
		/**
		 * Update color value taking into account parent and child colorAspects.
		 * @param	node
		 * @return
		 */
		private function updateColorAspects(node:ColorDisplayNode):Boolean
		{
			var colorAspect:ColorAspectData;
			var childrenColorAspect:ColorAspectData;
			
			var i:int;
			var j:int
			var validated:Boolean = true;
			for ( i = 0; i < node.colorSet.colorAspects.length; i++ )
			{
				colorAspect =  node.colorSet.colorAspects[i];
				if ( colorAspect.invalidate )	
				{
					//update from parent
					if ( colorAspect.parentColor )
					{
						if ( colorAspect.parentColor.invalidate )
						{
							validated = false;
							continue;
						}
						else 
						{
							colorAspect.value = colorAspect.parentColor.value;
						}
					}
					
					//update children
					if ( colorAspect.childrenColors )
					{
						for ( j = 0; j < colorAspect.childrenColors.length; j++ )
						{
							childrenColorAspect = colorAspect.childrenColors[j];
							//childrenColorAspect.value = colorAspect.value;
							childrenColorAspect.invalidate = true;
						}
					}
					
					colorAspect.invalidate = false;
				}
			}
			return validated;
		}
		
		/**
		 * Apply colors to colorable clips.
		 * @param	node
		 */
		private function updateColorableClips(node:ColorDisplayNode, displayObject:DisplayObjectContainer):void
		{
			var colorableData:ColorableData;
			var clip:DisplayObject;
			var colorAspect:ColorAspectData;
			var instanceData:InstanceData;
			
			var i:int;
			var j:int;
			for ( i = 0; i < node.colorSet.colorableClips.length; i++ )
			{
				colorableData =  node.colorSet.colorableClips[i];
				
				if ( DataUtils.validString( colorableData.colorId ) ) 
				{	
					colorAspect = node.colorSet.getColorAspect( colorableData.colorId );
				}
				else
				{
					colorAspect = node.colorSet.getColorAspectLast();
				}
				
				if ( colorAspect )
				{
					for ( j = 0; j < colorableData.instances.length; j++ )
					{
						instanceData = colorableData.instances[j];
						clip = instanceData.getInstanceFrom( displayObject );
						if ( clip )
						{
							// check colorable for it's own darken value, overrides colorSet
							ColorUtil.colorize( clip, colorAspect.getAdjustedColor( colorableData.darken ));
						}
					}
				}
			}
		}

	}
}