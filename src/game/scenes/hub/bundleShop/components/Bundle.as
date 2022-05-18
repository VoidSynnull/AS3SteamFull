package game.scenes.hub.bundleShop.components
{
	import ash.core.Component;
	
	import game.data.bundles.BundleData;
	
	public class Bundle extends Component
	{
		public function Bundle()
		{
			super();
		}
		
		public var bundleData:BundleData;
		public var index:int;
	}
}