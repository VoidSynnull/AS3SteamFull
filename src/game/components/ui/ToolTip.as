package game.components.ui
{
	import ash.core.Component;

	public class ToolTip extends Component
	{
		public var showing:Boolean;         // determines if visible or not
		public var viewedOnce:Boolean      // if never viewed before, will bounce in.
		public var type:String;
		public var loadingAsset:Boolean;
		public var label:String;
	}
}
