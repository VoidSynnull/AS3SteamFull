package game.components.ui
{	
	import ash.core.Component;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class TextDisplay extends Component
	{
		public function TextDisplay()
		{
			_lines = new Vector.<String>;
			_lines.push( new String("") );
			tf = new TextField();
		}

		public var queue:String = "";			// incoming chars
		public var tf:TextField;
		public var delay:int = 0;				// delay between each letter presentation
		public var wordWrap:Boolean = true;
		public var lineMax:int = 0;				// maximum number of lines allowed
		public var lineCharMax:int = 0;			// maximum number of characters allow in each line
		public var lineScroll:Boolean = true;	// flag determining if lines will scroll upwards when lineMax is exceeded
		
		public var hasCaret:Boolean = false;
		public var isCaretBlink:Boolean = true;
		public var caretDelay:int = 31;			// delay between each caret blink

		// system only 
		public var _deletes:int = 0;			// number of deletes
		public var _duration:int = 0;			// counter for delay
		
		public var _lines:Vector.<String>;		// stores each line as a separate string, does not include new nline comments
		public var _lineIndex:int = 0;			// active line, index starts at 0
		public var _isFull:Boolean = false;		// flag for whens max lines and maximum allowed chars is reached
		public var _clear:Boolean = false;
		
		public var _caret:Sprite;
		public var _caretCounter:int = 0;		// counter for caret blink
		
		/**
		 * Clear all text
		 */
		public function clear():void
		{
			_clear = true;
		}
		
		public function deleteLine():void
		{
			_deletes++;
		}
	}
}