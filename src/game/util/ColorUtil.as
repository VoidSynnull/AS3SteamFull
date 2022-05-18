package game.util 
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	
	import fl.motion.Color;

    public class ColorUtil
    {
		import game.util.Utils;		// gives randInRange()

		/**
		 * Generates a random 24-bit color, avoiding those which are too dark to distinguish.
		 */
		public static function get anyColor():uint 
		{
			var red:uint = Utils.randInRange(32, 255) as uint;
			var green:uint = Utils.randInRange(32, 255) as uint;
			var blue:uint = Utils.randInRange(32, 255) as uint;
			return Number((red << 16) | (green << 8) | blue);
		}

		public static function clampToColors(data:BitmapData, rgbColors:Vector.<Vector.<uint>>):void
		{
			var color:uint;
			var colorRGB:Vector.<uint>;
			
			for(var x:int = 0; x < data.width; x++)
			{
				for(var y:int = 0; y < data.height; y++)
				{
					color = data.getPixel(x, y);
					
					if(color != 0)
					{
						colorRGB = getClosestColor(ColorUtil.hexToRgb(color), rgbColors);
						
						data.setPixel32(x, y, 0xff000000 + ColorUtil.rgbToHex(colorRGB[0], colorRGB[1], colorRGB[2]));
						
						var colorDelta:Number = ColorUtil.rgbToHex(colorRGB[0], colorRGB[1], colorRGB[2]) - color;
					}
				}
			}
		}
		
		public static function getClosestColor(rgbColor:Vector.<uint>, rgbColors:Vector.<Vector.<uint>>):Vector.<uint>
		{
			var bestMatch:Vector.<uint>;
			var leastDifference:int = 766;
			var currentDifference:int;
			
			for(var n:uint = 0; n < rgbColors.length; n++)
			{
				currentDifference = Math.abs(rgbColor[0] - rgbColors[n][0]) + Math.abs(rgbColor[1] - rgbColors[n][1]) + Math.abs(rgbColor[2] - rgbColors[n][2]);
				
				if(currentDifference < leastDifference)
				{
					leastDifference = currentDifference;
					bestMatch = rgbColors[n];
				}
			}
			
			return(bestMatch);
		}

		public static function getRGBColorDifference(rgbColor1:Vector.<uint>, rgbColor2:Vector.<uint>):uint
		{
			return(Math.abs(rgbColor1[0] - rgbColor2[0]) + Math.abs(rgbColor1[1] - rgbColor2[1]) + Math.abs(rgbColor1[2] - rgbColor2[2]));
		}
		
		public static function colorize( displayObject:DisplayObject, hexColor:Number):void
		{
			var colorTransform:ColorTransform = displayObject.transform.colorTransform;
			colorTransform.color = hexColor;
			displayObject.transform.colorTransform = colorTransform;
		}
		
		public static function tint( displayObject:DisplayObjectContainer, hexColor:Number, tintPercent:int):void
		{
			var color:Color  = new Color();  
			color.setTint( hexColor, (tintPercent/100) );  
			displayObject.transform.colorTransform = color;
		}
		
        public static function brightenColor(hexColor:Number, percent:Number):Number
		{
            if(isNaN(percent))
                percent=0;
            if(percent>100)
                percent=100;
            if(percent<0)
                percent=0;
            
            var factor:Number=percent/100;
            var rgb:Vector.<uint>=hexToRgb(hexColor);
                        
            rgb[0]+=(255-rgb[0])*factor;
            rgb[1]+=(255-rgb[1])*factor;
            rgb[2]+=(255-rgb[2])*factor;
            
            return rgbToHex(Math.round(rgb[0]),Math.round(rgb[2]),Math.round(rgb[1]));
        }
        
		/**
		 * Darkens color.  Percent is 0 to 100.
		 * @param	hexColor
		 * @param	percent
		 * @return
		 */
        public static function darkenColor(hexColor:Number, percent:Number):Number
		{
            if(isNaN(percent))
                percent=0;
            if(percent>1)
                percent=1;
            if(percent<0)
                percent=0;
                
            var factor:Number= 1 - percent;
            var rgb:Vector.<uint>=hexToRgb(hexColor);
           
            rgb[0]*=factor;
            rgb[1]*=factor;
            rgb[2]*=factor;
            
            return rgbToHex(Math.round(rgb[0]),Math.round(rgb[1]),Math.round(rgb[2]));
        }
        
		public static function rgbVectorToHex(rgbColor:Vector.<uint>):uint 
		{
			return(rgbColor[0] << 16 | rgbColor[1] << 8 | rgbColor[2]);
		}
		
        public static function rgbToHex(r:uint, g:uint, b:uint):uint 
		{
			return(r << 16 | g << 8 | b);
        }

        public static function hexToRgb (hex:uint):Vector.<uint>
		{
			return(new <uint>[(hex >> 16) & 0xFF, (hex >> 8) & 0xFF, hex & 0xFF]);
        }
		
        public static function brightness(hex:uint):uint
		{
            var max:uint = 0;
            var rgb:Vector.<uint> = hexToRgb(hex);
            
			if(rgb[0] > max) { max = rgb[0]; }
            if(rgb[1] > max) { max = rgb[1]; }
            if(rgb[2] > max) { max = rgb[2]; }
            
			max/=255;
				
            return max;
        }
		
		public static function tintMatrixFilter(hex:uint, saturation:Number):ColorMatrixFilter
		{
			var rgb:Vector.<uint> = ColorUtil.hexToRgb(hex);
			var r:Number = rgb[0] / 255;
			var g:Number = rgb[1] / 255;
			var b:Number = rgb[2] / 255;
			var matrix:Array = [];
			
			matrix = matrix.concat([r*saturation, 0, 0, 0, 0]); // red
			matrix = matrix.concat([0, g*saturation, 0, 0, 0]); // green
			matrix = matrix.concat([0, 0, b*saturation, 0, 0]); // blue
			matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
			
			return  new ColorMatrixFilter(matrix);
		}
		
		public static function grayScaleMatrixFilter(saturation:Number):ColorMatrixFilter
		{
			var matrix:Array = [];
			matrix = matrix.concat([saturation, saturation, saturation, 0, 0]); // red
			matrix = matrix.concat([saturation, saturation, saturation, 0, 0]); // green
			matrix = matrix.concat([saturation, saturation, saturation, 0, 0]); // blue
			matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
			
			return  new ColorMatrixFilter(matrix);
		}
		
		public static function getAlpha(hexidecimal:uint):uint
		{
			return hexidecimal >> 24 & 255;
		}
		
		public static function getRed(hexidecimal:uint):uint
		{
			return hexidecimal >> 16 & 255;
		}
		
		public static function getGreen(hexidecimal:uint):uint
		{
			return hexidecimal >> 8 & 255;
		}
		
		public static function getBlue(hexidecimal:uint):uint
		{
			return hexidecimal & 255;
		}
    }
}
