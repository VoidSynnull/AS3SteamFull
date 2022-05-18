package game.data.tutorials
{
	import game.data.ui.GestureData;

	public class StepData
	{
		/**
		 * 
		 * @param id - id of the step, needed to link steps
		 * @param backAlpha - the alpha of the overlay
		 * @param color - the color of the overlay
		 * @param delay - delay before bringing this step up
		 * @param blur - blur the shapes?
		 * @param shapeData - the shapes you would like to cut out of the overlay
		 * @param textData - the text to be put on top of the overlay
		 * @param imageData - the images to be put on top the overlay
		 * 
		 */		
		public function StepData(id:String, backAlpha:Number, color:uint = 0x000000, delay:Number = 0, blur:Boolean = false, shapeData:Vector.<ShapeData> = null, textData:Vector.<TextData> = null, imageData:Vector.<ImageData> = null, gestureData:Vector.<GestureData> = null)
		{
			this.id = id;
			this.alpha = backAlpha;
			this.delay = delay;
			this.useBlur = blur;			

			this.shapeData = shapeData;
			this.textData = textData;
			this.imageData = imageData;
			this.gestureData = gestureData;
		}
		
		public var id:String;
		public var color:uint = 0x000000;
		public var alpha:Number = .95;
		public var delay:Number = 0;
		public var useBlur:Boolean;
		public var shapeData:Vector.<ShapeData>;
		public var textData:Vector.<TextData>;	
		public var imageData:Vector.<ImageData>;
		public var gestureData:Vector.<GestureData>;
	}
}