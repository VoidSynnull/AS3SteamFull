/*****************************************************
 * DisplayPositionUtils
 * 
 * Author : Billy Belfield
 * Date : 6/1/09
 * 
 * Consts defined for display element positions.
 * ***************************************************/

package game.util
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;

	public class DisplayPositionUtils
	{	

		/////////////////////////////////////////////////////////////////
		////////////////////////// POSITIONING //////////////////////////
		/////////////////////////////////////////////////////////////////
		
		/**
		 * Positions element using provide params, assumes DisplayObject element is positoned with a top left registration
		 * @param	element
		 * @param	edge : constants that are accessible from DisplayPositions (BOTTOM_LEFT, BOTTOM_RIGHT, BOTTOM_CENTER, TOP_LEFT, etc.)
		 * @param	width
		 * @param	height
		 * @param	paddingX
		 * @param	paddingY
		 * @param	offsetX
		 * @param	offsetY
		 */
		public static function position(element:DisplayObject, edge:String, width:Number, height:Number, paddingX:Number = 0, paddingY:Number = 0, offsetX:Number = 0, offsetY:Number = 0):void
		{
			switch(edge)
			{
				case DisplayPositions.BOTTOM_LEFT :
				element.x = paddingX + offsetX;				
				element.y = height - element.height - paddingY + offsetY;
				break;
				
				case DisplayPositions.BOTTOM_RIGHT :
				element.x = width - element.width - paddingX + offsetX;	
				element.y = height - element.height - paddingY + offsetY;
				break;
				
				case DisplayPositions.BOTTOM_CENTER :
				element.x = offsetX + width * .5 - element.width * .5;	
				element.y = height - element.height - paddingY + offsetY;
				break;				
				
				case DisplayPositions.TOP_LEFT :
				element.x = paddingX + offsetX;				
				element.y = paddingY + offsetY;
				break;
				
				case DisplayPositions.TOP_RIGHT :
				element.x = width - element.width - paddingX + offsetX;			
				element.y = paddingY + offsetY;
				break;
				
				case DisplayPositions.TOP_CENTER :
				element.x = offsetX + width * .5 - element.width * .5;					
				element.y = paddingY + offsetY;
				break;				
				
				case DisplayPositions.CENTER :
				element.x = offsetX + width * .5 - element.width * .5;				
				element.y = offsetY + height * .5 - element.height * .5;
				break;
				
				case DisplayPositions.LEFT_CENTER :
				element.x = paddingX + offsetX;			
				element.y = offsetY + height * .5 - element.height * .5;
				break;
				
				case DisplayPositions.RIGHT_CENTER :
				element.x = width - element.width - paddingX + offsetX;		
				element.y = offsetY + height * .5 - element.height * .5;
				break;
			}
		}
		
		/**
		 * Positions element using provide params, does not account for DisplayObject's height and width.
		 * @param	element
		 * @param	edge : constants that are accessible from DisplayPositions (BOTTOM_LEFT, BOTTOM_RIGHT, BOTTOM_CENTER, TOP_LEFT, etc.)
		 * @param	width
		 * @param	height
		 * @param	paddingX
		 * @param	paddingY
		 * @param	offsetX
		 * @param	offsetY
		 */
		public static function positionAbsolute(element:DisplayObject, edge:String, width:Number, height:Number, paddingX:Number = 0, paddingY:Number = 0, offsetX:Number = 0, offsetY:Number = 0):void
		{
			switch(edge)
			{
				case DisplayPositions.BOTTOM_LEFT :
					element.x = paddingX + offsetX;				
					element.y = height - paddingY + offsetY;
					break;
				
				case DisplayPositions.BOTTOM_RIGHT :
					element.x = width - paddingX + offsetX;	
					element.y = height - paddingY + offsetY;
					break;
				
				case DisplayPositions.BOTTOM_CENTER :
					element.x = offsetX + width * .5;	
					element.y = height - paddingY + offsetY;
					break;				
				
				case DisplayPositions.TOP_LEFT :
					element.x = paddingX + offsetX;				
					element.y = paddingY + offsetY;
					break;
				
				case DisplayPositions.TOP_RIGHT :
					element.x = width - paddingX + offsetX;			
					element.y = paddingY + offsetY;
					break;
				
				case DisplayPositions.TOP_CENTER :
					element.x = offsetX + width * .5;					
					element.y = paddingY + offsetY;
					break;				
				
				case DisplayPositions.CENTER :
					element.x = offsetX + width * .5;				
					element.y = offsetY + height * .5;
					break;
				
				case DisplayPositions.LEFT_CENTER :
					element.x = paddingX + offsetX;			
					element.y = offsetY + height * .5;
					break;
				
				case DisplayPositions.RIGHT_CENTER :
					element.x = width - paddingX + offsetX;		
					element.y = offsetY + height * .5;
					break;
			}
		}
		
		/**
		 * Returns the positions based on provided provide params, assumes a top left registration for asset.
		 * @param   positionString- String defining position, refer to DisplayPositions for valid types
		 * @param	width - width of element being positioning
		 * @param	height - width of element being positioning
		 * @param	paddingX - padding along x axis
		 * @param	paddingY - padding along y axis
		 * @param	offsetX - additional offset along x axis
		 * @param	offsetY - additional offset along y axis
		 * @return
		 */
		public static function getPosition( positionString:String, width:Number, height:Number, paddingX:Number = 0, paddingY:Number = 0, offsetX:Number = 0, offsetY:Number = 0):Point
		{
			var position:Point = new Point();
			switch(positionString)
			{
				case DisplayPositions.BOTTOM_LEFT :
				position.x = paddingX + offsetX;				
				position.y = height - paddingY + offsetY;
				break;
				
				case DisplayPositions.BOTTOM_RIGHT :
				position.x = width - paddingX + offsetX;	
				position.y = height - paddingY + offsetY;
				break;
				
				case DisplayPositions.BOTTOM_CENTER :
				position.x = offsetX + width * .5;	
				position.y = height - paddingY + offsetY;
				break;				
				
				case DisplayPositions.TOP_LEFT :
				position.x = paddingX + offsetX;				
				position.y = paddingY + offsetY;
				break;
				
				case DisplayPositions.TOP_RIGHT :
				position.x = width - paddingX + offsetX;			
				position.y = paddingY + offsetY;
				break;
				
				case DisplayPositions.TOP_CENTER :
				position.x = offsetX + width * .5;					
				position.y = paddingY + offsetY;
				break;				
				
				case DisplayPositions.CENTER :
				position.x = offsetX + width * .5;				
				position.y = offsetY + height * .5;
				break;
				
				case DisplayPositions.LEFT_CENTER :
				position.x = paddingX + offsetX;			
				position.y = offsetY + height * .5;
				break;
				
				case DisplayPositions.RIGHT_CENTER :
				position.x = width- paddingX + offsetX;		
				position.y = offsetY + height * .5;
				break;
			}
			return position;
		}
		
		/**
		 * Positions Entity within defined area by specified position. 
		 * @param	edge - use DisplayPositions constants
		 * @param	width - width of area positioning within
		 * @param	height - height of area positioning within
		 * @param	offsetX - additional offset along x axis
		 * @param	offsetY - additional offset along y axis
		 * @param dispalyOrientation - orientation of display, used if Entity does not ahve an Edge component
		 * @return
		 */
		public static function positionEntity( entity:Entity, positionString:String, width:Number, height:Number, offsetX:Number = 0, offsetY:Number = 0, displayOrientation:String='center'):void
		{
			var spatial:Spatial = entity.get(Spatial);
			if( spatial )
			{
				var top:Number;
				var bottom:Number;
				var right:Number;
				var left:Number;
				
				var edge:Edge = entity.get(Edge);
				if( edge )
				{
					top = edge.rectangle.top;
					bottom = edge.rectangle.bottom;
					right = edge.rectangle.right;
					left = edge.rectangle.left;
				}
				else
				{
					// assumes a center coordinate in the case of the display
					var display:Display = entity.get(Display);
					if( display && display.displayObject )
					{
						var displayWidth:Number = display.displayObject.width;
						var displayHeight:Number = display.displayObject.height;
						switch(displayOrientation)
						{
							case DisplayPositions.BOTTOM_LEFT :
								top = displayHeight;
								bottom = 0;
								right = displayWidth;
								left = 0;
								break;
							
							case DisplayPositions.BOTTOM_RIGHT :
								top = displayHeight;
								bottom = 0;
								right = 0;
								left = displayWidth;
								break;
							
							case DisplayPositions.BOTTOM_CENTER :
								top = displayHeight;
								bottom = 0;
								right = displayWidth/2;
								left = displayWidth/2;
								break;				
							
							case DisplayPositions.TOP_LEFT :
								top = 0;
								bottom = displayHeight;
								right = displayWidth;
								left = 0;
								break;
							
							case DisplayPositions.TOP_RIGHT :
								top = 0;
								bottom = displayHeight;
								right = 0;
								left = displayWidth;
								break;
							
							case DisplayPositions.TOP_CENTER :
								top = 0;
								bottom = displayHeight;
								right = displayWidth/2;
								left = displayWidth/2;
								break;				
							
							case DisplayPositions.CENTER :
								top = displayHeight/2;
								bottom = displayHeight/2;
								right = displayWidth/2;
								left = displayWidth/2;
								break;
							
							case DisplayPositions.LEFT_CENTER :
								top = displayHeight/2;
								bottom = displayHeight/2;
								right = displayWidth;
								left = 0;
								break;
							
							case DisplayPositions.RIGHT_CENTER :
								top = displayHeight/2;
								bottom = displayHeight/2;
								right = 0;
								left = displayWidth;
								break
						}
						
						top = bottom = display.displayObject.height/2;
						right = left = display.displayObject.width/2;
					}
					else
					{
						return;
					}	
				}

				switch(positionString)
				{
					case DisplayPositions.BOTTOM_LEFT :
						spatial.x = left + offsetX;				
						spatial.y = height - bottom + offsetY;
						break;
					
					case DisplayPositions.BOTTOM_RIGHT :
						spatial.x = width - right + offsetX;	
						spatial.y = height - bottom + offsetY;
						break;
					
					case DisplayPositions.BOTTOM_CENTER :
						spatial.x = offsetX + width * .5;	
						spatial.y = height - bottom + offsetY;
						break;				
					
					case DisplayPositions.TOP_LEFT :
						spatial.x = left + offsetX;					
						spatial.y = top + offsetY;
						break;
					
					case DisplayPositions.TOP_RIGHT :
						spatial.x = width - right + offsetX;			
						spatial.y = top + offsetY;
						break;
					
					case DisplayPositions.TOP_CENTER :
						spatial.x = offsetX + width * .5;					
						spatial.y = top + offsetY;
						break;				
					
					case DisplayPositions.CENTER :
						spatial.x = offsetX + width * .5;				
						spatial.y = offsetY + height * .5;
						break;
					
					case DisplayPositions.LEFT_CENTER :
						spatial.x = left + offsetX;		
						spatial.y = height - bottom + offsetY;
						break;
					
					case DisplayPositions.RIGHT_CENTER :
						spatial.x = width - right + offsetX;	
						spatial.y = height - bottom + offsetY;
						break;
				}
			}
		}
		
		/**
		 * Scale element to fit within provided params
		 * @param	element
		 * @param	width
		 * @param	height
		 * @param	center
		 */
		public static function fitToDimensions(element:DisplayObject, width:Number, height:Number, center:Boolean):void 
		{
			//var ratio:Number = element.height / element.width;
			
			element.width = width;
			element.height = height;
			
			if(element.scaleX > element.scaleY)
			{
				element.scaleX = element.scaleY;
			}
			else
			{
				element.scaleY = element.scaleX;
			}
			
			if(center)
			{
				centerWithinDimensions(element, width, height);
			}
		}
		

		/**
		 * Scale element to fit along a specific dimension
		 * @param element - element to be scaled
		 * @param dimensionLength - length of dimension to scal eup to (for example if scaling horizontally might provide viewport wisth)
		 * @param fitHorizontally - flag determining which dimemsion to scale to
		 */
		public static function fitToSingleDimension(element:DisplayObject, dimensionLength:Number, fitHorizontally:Boolean = true):void 
		{
			if( fitHorizontally )
			{
				element.width = dimensionLength;
				element.scaleY = element.scaleX;
			}
			else
			{
				element.height = dimensionLength;
				element.scaleX = element.scaleY;
			}
		}
		
		/**
		 * Scale element to fit within provided params
		 * @param	element
		 * @param	width
		 * @param	height
		 */
		public static function fillDimensions(element:DisplayObject, width:Number, height:Number):void 
		{			
			element.width = width;
			element.height = height;
			
			if(element.scaleX < element.scaleY)
			{
				element.scaleX = element.scaleY;
			}
			else
			{
				element.scaleY = element.scaleX;
			}
		}
		
		/**
		 * Scale element to fit within stage params
		 * @param	element
		 * @param	elementStageWidth
		 * @param	elementStageHeight
		 * @param	newStageWidth
		 * @param	newStageHeight
		 * @param	center
		 */
		public static function fitToStage(element:DisplayObject, elementStageWidth:Number, elementStageHeight:Number, newStageWidth:Number, newStageHeight:Number, center:Boolean):void
		{			
			// Determine the % of the current screen the stage occupies
			var scaleFactorX:Number = newStageHeight / elementStageHeight;
			var scaleFactorY:Number = newStageWidth / elementStageWidth;
			var scaleFactor:Number;
			var oWidth:Number = element.width;
			var oHeight:Number = element.height;
			
			if (scaleFactorX > scaleFactorY)
			{
				scaleFactor = scaleFactorY;
			}
			else
			{
				scaleFactor = scaleFactorX;
			}
			
			if (scaleFactor != 1)
			{
				element.scaleX = element.scaleY = scaleFactor;
				
				if(center)
				{
					centerWithinDimensions(element, newStageWidth, newStageHeight, oWidth * scaleFactor, oHeight * scaleFactor);
				}
			}
		}
		
		/**
		 * Center display element within provide params.
		 * @param	element
		 * @param	width
		 * @param	height
		 * @param	childClipToUseForCentering
		 */
		public static function centerWithinScreen(element:DisplayObject, shellApi:ShellApi):void
		{
			var b:Rectangle = element.getBounds(element);
			var width:Number = shellApi.viewportWidth;
			var height:Number = shellApi.viewportHeight;
			trace("centerize: " +b + " inside: " + new Rectangle(0,0,width, height));
			element.x = width/2 - (b.left + b.width/2);
			element.y = height/2 - (b.top + b.height/2);
		}
		
		/**
		 * Center display element within provide params.
		 * @param	element
		 * @param	width
		 * @param	height
		 * @param	initWidth
		 * @param	initHeight
		 */
		public static function centerWithinDimensions(element:DisplayObject, width:Number, height:Number, initWidth:Number = NaN, initHeight:Number = NaN):void
		{					
			if(isNaN(initWidth)) { initWidth = element.width; }
			if(isNaN(initHeight)) { initHeight = element.height; }
			
			var deltaX:Number = width - initWidth;
			var deltaY:Number = height - initHeight;
			
			element.x = deltaX * .5;
			element.y = deltaY * .5;
		}
	}
}