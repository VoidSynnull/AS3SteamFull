package game.util
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	/**
	 * DisplayAlignment is a utility class designed to fit, fill, and stretch DisplayObjects
	 * to fit any given area.
	 * 
	 * @author Drew Martin
	 */
	public final class DisplayAlignment
	{
		/**
		 * These constants are used for DisplayObject positioning along the side of a value.
		 * 
		 * <p>With each table cell as the bounds/edge:
		 * <table>
		 * <tr> <td></td>      <td>MIN_Y</td><td>   </td></tr>
		 * <tr> <td>MIN_X</td> <td>MID_X/MID_Y</td> <td>MAX_X</td> </tr>
		 * <tr> <td></td>      <td>MAX_Y</td>       <td></td>      </tr>
		 * </table>
		 */
		public static const MIN_X:String = "min_x";
		public static const MID_X:String = "mid_x";
		public static const MAX_X:String = "max_x";
		public static const MIN_Y:String = "min_y";
		public static const MID_Y:String = "mid_y";
		public static const MAX_Y:String = "max_y";
		
		/**
		 * These constants are used for DisplayObject positioning within the area of a Rectangle.
		 * 
		 * <p>With this table as a Rectangle:
		 * <table>
		 * <tr> <td>MIN_X_MIN_Y</td> <td>MID_X_MIN_Y</td> <td>MAX_X_MIN_Y</td> </tr>
		 * <tr> <td>MIN_X_MID_Y</td> <td>MID_X_MID_Y</td> <td>MAX_X_MID_Y</td> </tr>
		 * <tr> <td>MIN_X_MAX_Y</td> <td>MID_X_MAX_Y</td> <td>MAX_X_MAX_Y</td> </tr>
		 * </table>
		 */
		public static const MIN_X_MIN_Y:String = "min_x_min_y";
		public static const MID_X_MIN_Y:String = "mid_x_min_y";
		public static const MAX_X_MIN_Y:String = "max_x_min_y";
		public static const MIN_X_MID_Y:String = "min_x_mid_y";
		public static const MID_X_MID_Y:String = "mid_x_mid_y";
		public static const MAX_X_MID_Y:String = "max_x_mid_y";
		public static const MIN_X_MAX_Y:String = "min_x_max_y";
		public static const MID_X_MAX_Y:String = "mid_x_max_y";
		public static const MAX_X_MAX_Y:String = "max_x_max_y";
		
		public static function stretch(display:DisplayObject, width:Number, height:Number, bounds:Rectangle = null):Rectangle
		{
			bounds = bounds ? bounds : DisplayAlignment.getBounds(display);
			return DisplayAlignment.resize(display, bounds, width / bounds.width, height / bounds.height);
		}
		
		public static function fit(display:DisplayObject, width:Number, height:Number, bounds:Rectangle = null):Rectangle
		{
			bounds = bounds ? bounds : DisplayAlignment.getBounds(display);
			var ratio:Number = Math.min(width / bounds.width, height / bounds.height);
			return DisplayAlignment.resize(display, bounds, ratio, ratio);
		}
		
		public static function fill(display:DisplayObject, width:Number, height:Number, bounds:Rectangle = null):Rectangle
		{
			bounds = bounds ? bounds : DisplayAlignment.getBounds(display);
			var ratio:Number = Math.max(width / bounds.width, height / bounds.height);
			return DisplayAlignment.resize(display, bounds, ratio, ratio);
		}
		
		public static function stretchAndAlign(display:DisplayObject, area:Rectangle, bounds:Rectangle = null, alignment:String = MID_X_MID_Y):Rectangle
		{
			bounds = DisplayAlignment.stretch(display, area.width, area.height, bounds);
			return DisplayAlignment.alignToArea(display, area, bounds, alignment);
		}
		
		public static function fitAndAlign(display:DisplayObject, area:Rectangle, bounds:Rectangle = null, alignment:String = MID_X_MID_Y):Rectangle
		{
			bounds = DisplayAlignment.fit(display, area.width, area.height, bounds);
			return DisplayAlignment.alignToArea(display, area, bounds, alignment);
		}
		
		public static function fillAndAlign(display:DisplayObject, area:Rectangle, bounds:Rectangle = null, alignment:String = MID_X_MID_Y):Rectangle
		{
			bounds = DisplayAlignment.fill(display, area.width, area.height, bounds);
			return DisplayAlignment.alignToArea(display, area, bounds, alignment);
		}
		
		public static function alignToArea(display:DisplayObject, area:Rectangle, bounds:Rectangle = null, alignment:String = MID_X_MID_Y):Rectangle
		{
			bounds = bounds ? bounds.clone() : DisplayAlignment.getBounds(display);
			
			switch(alignment)
			{
				case DisplayAlignment.MIN_X_MIN_Y:
					DisplayAlignment.alignToSide(display, area.left, bounds, MIN_X);
					DisplayAlignment.alignToSide(display, area.top, bounds, MIN_Y);
					break;
				
				case DisplayAlignment.MID_X_MIN_Y:
					DisplayAlignment.alignToSide(display, area.left + area.width * 0.5, bounds, MID_X);
					DisplayAlignment.alignToSide(display, area.top, bounds, MIN_Y);
					break;
				
				case DisplayAlignment.MAX_X_MIN_Y:
					DisplayAlignment.alignToSide(display, area.right, bounds, MAX_X);
					DisplayAlignment.alignToSide(display, area.top, bounds, MIN_Y);
					break;
				
				case DisplayAlignment.MIN_X_MID_Y:
					DisplayAlignment.alignToSide(display, area.left, bounds, MIN_X);
					DisplayAlignment.alignToSide(display, area.top + area.height * 0.5, bounds, MID_Y);
					break;
				
				case DisplayAlignment.MID_X_MID_Y:
					DisplayAlignment.alignToSide(display, area.left + area.width * 0.5, bounds, MID_X);
					DisplayAlignment.alignToSide(display, area.top + area.height * 0.5, bounds, MID_Y);
					break;
				
				case DisplayAlignment.MAX_X_MID_Y:
					DisplayAlignment.alignToSide(display, area.right, bounds, MAX_X);
					DisplayAlignment.alignToSide(display, area.top + area.height * 0.5, bounds, MID_Y);
					break;
				
				case DisplayAlignment.MIN_X_MAX_Y:
					DisplayAlignment.alignToSide(display, area.left, bounds, MIN_X);
					DisplayAlignment.alignToSide(display, area.bottom, bounds, MAX_Y);
					break;
				
				case DisplayAlignment.MID_X_MAX_Y:
					DisplayAlignment.alignToSide(display, area.left + area.width * 0.5, bounds, MID_X);
					DisplayAlignment.alignToSide(display, area.bottom, bounds, MAX_Y);
					break;
				
				case DisplayAlignment.MAX_X_MAX_Y:
					DisplayAlignment.alignToSide(display, area.right, bounds, MAX_X);
					DisplayAlignment.alignToSide(display, area.bottom, bounds, MAX_Y);
					break;
			}
			
			bounds.x += display.x;// + bounds.x;
			bounds.y += display.y;// + bounds.y;
			
			return bounds;
		}
		
		public static function alignToSide(display:DisplayObject, side:Number, bounds:Rectangle = null, alignment:String = MID_X):void
		{
			bounds = bounds ? bounds : DisplayAlignment.getBounds(display);
			
			switch(alignment)
			{
				case DisplayAlignment.MIN_X:
					display.x = side - bounds.left;
					break;
				
				case DisplayAlignment.MID_X:
					display.x = side - bounds.left - bounds.width * 0.5;
					break;
				
				case DisplayAlignment.MAX_X:
					display.x = side - bounds.right;
					break;
				
				case DisplayAlignment.MIN_Y:
					display.y = side - bounds.top;
					break;
				
				case DisplayAlignment.MID_Y:
					display.y = side - bounds.top - bounds.height * 0.5;
					break;
				
				case DisplayAlignment.MAX_Y:
					display.y = side - bounds.bottom;
					break;
			}
		}
		
		private static function resize(display:DisplayObject, bounds:Rectangle, ratioX:Number, ratioY:Number):Rectangle
		{
			bounds = bounds.clone();
			
			display.scaleX *= ratioX;
			display.scaleY *= ratioY;
			
			bounds.x 		*= ratioX;
			bounds.y 		*= ratioY;
			bounds.width 	*= ratioX;
			bounds.height 	*= ratioY;
			
			return bounds;
		}
		
		public static function getBounds(display:DisplayObject):Rectangle
		{
			var bounds:Rectangle 	= display.getBounds(display.parent);
			bounds.x 				-= display.x;
			bounds.y 				-= display.y;
			return bounds;
		}
	}
}