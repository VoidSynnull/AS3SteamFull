package game.scenes.survival3.shared.components
{
	import ash.core.Component;
	
	import engine.components.Camera;
	
	public class ClimbingZoom extends Component
	{
		public var defaultZoom:Number;
		public var maxZoomOut:Number;
		public var differernce:Number;
		public var camera:Camera;
		public var startZoomPercent:Number;
		
		public function ClimbingZoom(camera:Camera, defaultZoom:Number = 1, maxZoomOut:Number = .25, startZoomPercent:Number = .5)
		{
			this.camera = camera;
			this.maxZoomOut = maxZoomOut;
			this.defaultZoom = defaultZoom;
			this.startZoomPercent = startZoomPercent;
			differernce = defaultZoom + startZoomPercent - maxZoomOut;
		}
	}
}