package game.scenes.virusHunter.shipDemo.components
{
	import ash.core.Component;
	
	public class Current extends Component
	{
		public var minWidth:Number;
		public var maxWidth:Number;
		public var curWidth:Number;
		public var maxHeight:Number;
		public var segments:Number;
		public var baseY:Number;
		public var steps:Number;
		public var maxOffset:Number;
		
		public var mid:Number;
		public var space:Number;
		public var hStep:Number;
		public var wStep:Number;
		
		public var thickness:int;
		public var color:uint;
		public var alpha:Number;
			
		/**
		 * Creates a movie clip of moving electric current.  Can increase in distance as the current moves along the y-axis. 
		 * @param	minimumWidth		width at the lowest point
		 * @param	maximumWidth		width at the hightest point of the arch
		 * @param	maximumHeight		highest point the current will reach
		 * @param	numSegments			X-axis divisions
		 * @param	rootY				base Y value of current
		 * @param	numSteps			Y-axis divisions
		 * @param	maximumOffset		highest potential displacement in the arc over any segment
		 * @param	thickness	An integer that indicates the thickness of the line in 
		 *   points; valid values are 0-255. If a number is not specified, or if the 
		 *   parameter is undefined, a line is not drawn. If a value of less than 0 is passed, 
		 *   the default is 0. The value 0 indicates hairline thickness; the maximum thickness 
		 *   is 255. If a value greater than 255 is passed, the default is 255.
		 * @param	color	A hexadecimal color value of the line; for example, red is 0xFF0000, blue is 
		 *   0x0000FF, and so on. If a value is not indicated, the default is 0x000000 (black). Optional.
		 */
		public function Current( minimumWidth:Number, maximumWidth:Number, maximumHeight:Number, numSegments:Number, rootY:Number, numSteps:Number, maximumOffset:Number, thickness:Number = 1, color:uint = 0x000000 )
		{
			this.minWidth = minimumWidth;
			this.maxWidth = maximumWidth;
			
			this.curWidth = minimumWidth;
			
			this.maxHeight = maximumHeight;
			this.segments = numSegments;
			this.baseY = rootY;
			this.steps = numSteps;
			this.maxOffset = maximumOffset;
			
			this.mid = numSegments / 2;
			this.space = minimumWidth / numSegments;
			this.hStep = maximumHeight / numSteps;
			this.wStep = ( maximumWidth - minimumWidth ) / numSteps;
			
			if ( thickness < 0 )
			{
				this.thickness = 0;
			}
			else if ( thickness > 255 )
			{
				this.thickness = 255;
			}
			else
			{
				this.thickness = thickness;
			}
			this.color = color;
		}
	}
}