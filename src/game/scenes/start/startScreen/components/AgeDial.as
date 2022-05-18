package game.scenes.start.startScreen.components
{
	import flash.display.DisplayObjectContainer;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import ash.core.Component;
	
	import game.util.TextUtils;
	
	import org.osflash.signals.Signal;
	
	public class AgeDial extends Component
	{
		//The Y difference between dial numbers/TextFields.
		public var offset:int	= 200;
		
		public var axis:String = "y";
		
		public var up:Boolean 		= false;
		public var down:Boolean 	= false;
		public var locked:Boolean 	= false;
		public var refresh:Boolean  = false;
		
		public var index:int;
		public var poolIndex:int;
		
		public var values:Array;
		
		public var current:TextField;
		
		public var textPool:Array;
		
		public var textClone:TextField;
		private var textContainer:DisplayObjectContainer;
		
		public var dialChanged:Signal;
		
		public var font:String;
		
		public function AgeDial(textClone:TextField, font:String = null)
		{
			this.textClone = textClone;
			textContainer = this.textClone.parent;
			this.textPool = [];
			dialChanged = new Signal(AgeDial);
			this.font = font;
		}
		
		public function resetValues(values:Array, index:int = -1):void
		{
			refresh = true;
			this.values = values;
			if(index < 0 || index >= values.length)
				index = int(Math.random() * values.length);
			this.index = index;
		}
		
		public function updatePool(poolSize:int = 2, fontSize:int = 96):void
		{
			var tf:TextField = textClone;
			updateTextField(tf, fontSize);
			var fraction:Number = poolSize-1;
			var maxSize:int = Math.max(poolSize, textPool.length);
			
			poolIndex = 0;
			
			var displayIndex:int = index;
			
			for(var i:int = 0; i < maxSize; i++)
			{
				if(displayIndex >= values.length)
					displayIndex = 0;
				//updating textfields that are being reused
				var center:Number;
				if(i < textPool.length && i < poolSize)
				{
					tf = textPool[i];
					tf.text = values[displayIndex];
					updateTextField(tf, fontSize);
					center = axis == "x"?-tf.width/2:-tf.height/2;
					tf[axis] = (offset /fraction) * (i-(poolSize/2-1)) + center;
					displayIndex++;
				}
				else
				{
					//updating new textfields to be added to pool
					if(i>=textPool.length)// if there are more textfields required than currently existing
					{
						tf = TextUtils.refreshText(textClone, font);
						textContainer.addChild(tf);
						tf.text = values[displayIndex];
						center = axis == "x"?-tf.width/2:-tf.height/2;
						tf[axis] = (offset /fraction) * (i-(poolSize/2-1)) + center;
						textPool.push(tf);
						displayIndex++;
					}
					else
					{
						// removing extra textfeilds no longer being used
						tf = textPool.pop();
						tf.parent.removeChild(tf);
						// need to make sure as we remove elements the loop doesn't go on longer than we want
						maxSize = Math.max(poolSize, textPool.length);
						i--;
					}
				}
			}
			
			current = textPool[textPool.length/2-1];
		}
		
		public function updateTextField(tf:TextField, fontSize:int):void
		{
			var format:TextFormat = tf.getTextFormat();
			format.size = fontSize;
			tf.defaultTextFormat = format;
			tf.setTextFormat(format);
			tf.autoSize = TextFieldAutoSize.CENTER;
		}
		
		public function get Displays():Number
		{
			return textPool.length-1;
		}
	}
}