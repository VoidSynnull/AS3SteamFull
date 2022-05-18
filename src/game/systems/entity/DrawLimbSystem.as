package game.systems.entity
{
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Engine;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.DrawLimb;
	import game.components.render.Line;
	import game.data.character.part.ColorAspectData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.DrawLimbNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.ColorUtil;
	
	/**
	 * Draws a 'limb' line for characters.
	 * Line is draw between 2 joint positions.
	 * The line acts as one of the 'parts'.
	 * The line's color is updated through the CharacterSkinSystem.
	 */
	public class DrawLimbSystem extends GameSystem
	{
		public var redrawnThreshold:int = THRESHOLD_DEFAULT;
		public const THRESHOLD_DEFAULT:int = 4;

		public function DrawLimbSystem()
		{
			super( DrawLimbNode, updateNode );
			super._defaultPriority = SystemPriorities.render;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
			super.onlyApplyLastUpdateOnCatchup = true;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(DrawLimbNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode( node:DrawLimbNode, time:Number ) : void
		{
			var drawLimb:DrawLimb = node.drawLimb;
			var spatial:Spatial = node.spatial;
			
			var distX:Number = drawLimb.leader.x - spatial.x;
			var distY:Number = drawLimb.leader.y - spatial.y;
			
			var colorAspect:ColorAspectData = node.colorSet.getColorAspectLast();
			if(!colorAspect) return;
			
			var colorHex:Number = colorAspect.getAdjustedColor();
			
			/**
			 * In an attempt to reduce the amount of redraws to limbs, DrawLimb components now hold a previousDistX, previousY, and
			 * previousColor values. If the changes in distance are greater than a hardcoded 5 pixels or the color has changed, then
			 * redraw. Otherwise, don't update.
			 */
			var parentSpatial:Spatial 	= node.parent.parent.get(Spatial);
			var threshold:Number 		= redrawnThreshold * (0.36 / parentSpatial.scaleY);
			
			if(Math.abs(drawLimb.previousDistX - distX) < threshold && Math.abs(drawLimb.previousDistY - distY) < threshold && drawLimb.previousColor == colorHex)
			{
				return;
			}
			
			drawLimb.previousDistX = distX;
			drawLimb.previousDistY = distY;
			drawLimb.previousColor = colorHex;
			
			var radians:Number = Math.atan( distY / distX );
			
			radians += Math.PI;
			if(distX < 0) radians += Math.PI;
			
			var distance:Number = Math.sqrt( distX * distX + distY * distY );
				
			if ( distance < drawLimb.maxDist ) 
			{
				var bend:Number = (Math.PI / 2) * (( drawLimb.maxDist - distance ) / drawLimb.maxDist );
				
				radians += drawLimb.isBendForward ? bend : -bend;
			}
			
			var bendX:Number = drawLimb.offset * Math.cos(radians);
			var bendY:Number = drawLimb.offset * Math.sin(radians);
			
			var display:Display = node.display;
			var line:Line = node.line;
			
			if(display.displayObject is MovieClip)
			{
				if(drawLimb.pose)
				{
					ColorUtil.colorize(display.displayObject, colorHex);
					return;
				}
				display.swapDisplayObject(new Sprite());
			}
			
			var graphics:Graphics = Sprite(display.displayObject).graphics;		// NOTE : Have to do casting to be able to use graphics
			graphics.clear();
			graphics.lineStyle( line.lineWidth, colorHex );
			graphics.curveTo( bendX, bendY, distX, distY );
		}
	}
}
