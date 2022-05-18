package game.data.tutorials
{
	import flash.geom.Point;
	
	import engine.components.Interaction;
	
	import org.osflash.signals.Signal;

	public class ShapeData
	{
		/**
		 * 
		 * @param type - what type of shape, use the constants in this class
		 * @param loc - the location of the shape in UI coordinates
		 * @param width - the width of the shape
		 * @param height - the height of the shape, ignored for Circle (uses width as radius)
		 * @param link - the step the clicking on this shape will take us too. If null, auto step to next stepData in vector
		 * @param skipLink - the step you want skipped, will need to remove it from the vector of steps.
		 * @param handler - what additionally should happen when this shape is clicked
		 * @param interaction - add an interaction if this is the click we should listen for, otherwise tutorial group will auto add one in the shapes location
		 * @param signal - add a signal if that's what you want to trigger the next step. DON'T do both interaction and signal
		 * 
		 */		
		public function ShapeData(type:String, loc:Point, width:Number, height:Number, link:String = null, skipLink:String = null, handler:Function = null, interaction:Interaction = null, signal:Signal = null)
		{
			shapeType = type;
			location = loc;
			this.width = width;
			this.height = height;
			
			this.clickLink = link;
			this.removeLink = skipLink;
			this.handler = handler;
			this.interaction = interaction;
			this.signal = signal;
		}
		
		public var shapeType:String;
		public var width:Number;
		public var height:Number;
		public var location:Point;
		public var clickLink:String;
		public var removeLink:String;
		public var handler:Function;
		public var interaction:Interaction;
		public var signal:Signal;
		
		public static const RECTANGLE:String 	= "rectangle";
		public static const CIRCLE:String 		= "circle";
		public static const ELLIPSE:String		= "ellipse";
		public static const CLOSE:String		= "close";
	}
}