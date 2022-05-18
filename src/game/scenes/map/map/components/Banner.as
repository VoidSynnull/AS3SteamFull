package game.scenes.map.map.components
{
	import flash.text.TextField;
	
	import ash.core.Component;

	public class Banner extends Component
	{
		public var page_start:int;
		public var page_end:int;
		public var textField:TextField;
		
		public function Banner(textField:TextField, page_start:int, page_end:int)
		{
			this.textField = textField;	
			this.page_start = page_start;
			this.page_end = page_end;
		}
		
		public function setText(text:String):void
		{
			this.textField.text = text;
		}
		
	}
}