package game.managers
{
	/**
	 * Create and remove UIViews and UIElements.  Provides shortcuts to creators for UIElements.  Contains its own SystemManager (Engine) and tickProvider (update loop) for 
	 *   uiviews that require systems and entities.
	 */
	
	import flash.display.DisplayObjectContainer;
	
	import engine.Manager;
	
	import game.util.DisplayPositionUtils;
	
	public class LayoutManager extends Manager
	{		
		/**
		 * Center a top-left registered displayObject on the x/y/or both axis.
		 * @param element : The displayObject to center.
		 * @param [axis] : The axis to center on.  Valid values are "x" or "y".  Will center on both by default. 
		 */		
		public function centerUI(element:DisplayObjectContainer, axis:String = null):void
		{
			//var bounds:Rectangle = element.getBounds(element.parent);
			
			if(axis == "x" || axis == null)
			{
				element.x = shellApi.viewportWidth * .5 - element.width * .5;
			}
			
			if(axis == "y" || axis == null)
			{
				element.y = shellApi.viewportHeight * .5 - element.height * .5;
			}
		}
		
		/**
		 * Apply the viewport offset to ui elements.  If the ui becomes wider or taller after being scaled to a new screensize this
		 *   will offset the elements on the right or bottom sides the difference.
		 * @param element : The displayObject to offset.
		 */
		public function applyOffsetToUI(element:DisplayObjectContainer):void
		{
			// container stays at 0,0 but may become taller or wider....
			if(element.x > shellApi.viewportWidth * .5)
			{
				element.x += shellApi.viewportDeltaX;
			}
			
			if(element.y > shellApi.viewportHeight * .5)
			{
				element.y += shellApi.viewportDeltaY;
			}
		}
		
		/**
		 * Fit a displayObject to the edge of the screen.
		 * @param element : Display object to pin.
		 * @param edge : The type of edge to pin to.  Valid types are:
		 *  game.util.DisplayPositions.BOTTOM_LEFT = "bottomLeft";
		 *  game.util.DisplayPositions.BOTTOM_RIGHT = "bottomRight";
		 *  game.util.DisplayPositions.BOTTOM_CENTER = "bottomCenter";
		 *  game.util.DisplayPositions.TOP_LEFT = "topLeft";
		 *  game.util.DisplayPositions.TOP_RIGHT = "topRight";
		 *  game.util.DisplayPositions.TOP_CENTER = "topCenter";
		 *  game.util.DisplayPositions.LEFT_CENTER = "leftCenter";
		 *  game.util.DisplayPositions.RIGHT_CENTER = "rightCenter";
		 *  game.util.DisplayPositions.CENTER:String = "center";
		 * 
		 * @param [paddingX] : X and Y padding to add to pinned elements.  Is added away from the edge being pinned to.
		 * @param [paddingY]
		 */
		public function pinToEdge(element:DisplayObjectContainer, edge:String, paddingX:Number = 0, paddingY:Number = 0):void
		{
			DisplayPositionUtils.position(element, edge, shellApi.viewportWidth, shellApi.viewportHeight, paddingX, paddingY);
		}
		
		/**
		 * Fit a displayObject with a 'content' and 'bg' subclip by offsetting content and stretching bg.
		 * @param screen : Display object to fit.
		 */
		public function fitUI(screen:DisplayObjectContainer):void
		{
			// center content
			if(screen["content"] != null)
			{
				screen["content"].x += shellApi.viewportDeltaX * .5;
				screen["content"].y += shellApi.viewportDeltaY * .5;
			}
			
			// stretch background
			if(screen["bg"])
			{
				screen["bg"].width = shellApi.viewportWidth;
				screen["bg"].height = shellApi.viewportHeight;
			}
		}
	}
}
