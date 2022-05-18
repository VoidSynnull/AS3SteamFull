package game.components.entity {

	import flash.display.DisplayObjectContainer;

	import ash.core.Component;

	public class ZDepthControl extends Component {

		public function ZDepthControl()
		{
		}

		// I don't think we need this. Maybe it's to indicate a complete re-depthing of everything?
		//public var _invalidate:Boolean = true;
		public var container:DisplayObjectContainer;
	}

}