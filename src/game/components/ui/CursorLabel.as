package game.components.ui
{
	import flash.text.TextField;
	
	import ash.core.Component;
	
	public class CursorLabel extends Component
	{
		public function CursorLabel(textField:TextField = null)
		{
			this.textField = textField;
		}
		
		public var textField:TextField;
		public var offsetY:int = -17;
	}
}