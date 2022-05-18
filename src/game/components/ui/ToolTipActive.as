package game.components.ui
{
	import ash.core.Component;
	
	// a marker component that can be added or removed to turn a tooltip on or off.
	public class ToolTipActive extends Component
	{
		// For cursors only, should the hittest use the parent's display for hittests?  Needed for tooltip entities which don't have their own
		//   display.
		public var useParentDisplayForHitTest:Boolean = true;
	}
}