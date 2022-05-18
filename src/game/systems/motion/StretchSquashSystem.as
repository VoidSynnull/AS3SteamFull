package game.systems.motion
{
	import engine.components.Spatial;
	
	import game.components.motion.StretchSquash;
	import game.nodes.motion.StretchSquashNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	/**
	 * Performs stretch or squash to an entity.
	 */
	public class StretchSquashSystem extends GameSystem
	{
		public function StretchSquashSystem()
		{
			super( StretchSquashNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:StretchSquashNode, time:Number):void
	    {
			var morph:StretchSquash = node.stretchSquash;
			var spatial:Spatial = node.spatial;
			
			if ( morph.active )
			{
				if ( morph._morphing )
				{
					// update anchor point position
					if ( morph.anchorEdge == morph.ANCHOR_BOTTOM )
					{
						node.spatialOffset.y = ( 1 - node.spatial.scaleY / node.spatial.scale ) * node.edge.rectangle.bottom;
					}
					else if ( morph.anchorEdge == morph.ANCHOR_TOP )
					{
						node.spatialOffset.y = ( 1 - node.spatial.scaleY / node.spatial.scale ) * node.edge.rectangle.top;
					}
					else if ( morph.anchorEdge == morph.ANCHOR_RIGHT )
					{
						node.spatialOffset.x = ( 1 - node.spatial.scaleX / node.spatial.scale ) * node.edge.rectangle.right;
					}
					else if ( morph.anchorEdge == morph.ANCHOR_LEFT )
					{
						node.spatialOffset.x = ( 1 - node.spatial.scaleX / node.spatial.scale ) * node.edge.rectangle.left;
					}
				}
				else
				{
					var xScale:Number;
					var yScale:Number;
					var direction:int = ( spatial.scaleX < 0 ) ? -1 : 1;
					
					if ( morph.state == morph.SQUASH )
					{
						if( morph.axis == "y" )
						{
							xScale = 1 + ( (1 - morph.scalePercent) * morph.inverseRate );
							yScale = morph.scalePercent;
						}
						else if ( morph.axis == "x" )
						{
							xScale = morph.scalePercent;
							yScale = 1 + ( (1 - morph.scalePercent) * morph.inverseRate );
						}
					}
					else if ( morph.state == morph.STRETCH )
					{
						if( morph.axis == "y" )
						{
							xScale = 1 - ( ( 1 - morph.scalePercent ) * morph.inverseRate );
							yScale = (2 - morph.scalePercent);
						}
						else if ( morph.axis == "x" )
						{
							xScale = (2 - morph.scalePercent);
							yScale = 1 - ( ( 1 - morph.scalePercent ) * morph.inverseRate );
						}
					}
					else if ( morph.state == morph.ORIGINAL )
					{
						xScale = 1;
						yScale = 1;
					}
					
					xScale = node.spatial.scale * xScale * direction;
					yScale = node.spatial.scale * yScale;
					
					node.tween.to( node.spatial, morph.duration,{ scaleX:xScale, ease:morph.transition, onComplete:morph.stateComplete }, "xTween" );
					node.tween.to( node.spatial, morph.duration, { scaleY:yScale, ease:morph.transition }, "yTween" );
					
					morph._morphing = true;
				}
			}
		}
	}
}
