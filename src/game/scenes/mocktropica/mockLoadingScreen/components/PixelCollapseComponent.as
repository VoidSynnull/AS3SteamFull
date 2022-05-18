package game.scenes.mocktropica.mockLoadingScreen.components
{		
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Display;
	
	public class PixelCollapseComponent extends Component
	{
		public var pixelSize:uint;
		public var gameWidth:uint;
		public var gameHeight:uint;
		public var pixels:Array = new Array();
		public var gravity:Number = 1;
		public var points:Array = new Array();
		public var display:Display;
		
		public function PixelCollapseComponent(display:Display, sceneWidth:uint, sceneHeight:uint, pixelSize:uint = 20)
		{
			this.display = display;
			this.pixelSize = pixelSize;
			gameWidth = sceneWidth;
			gameHeight = sceneHeight;
			var cols:uint = Math.ceil(gameWidth/pixelSize);
			var rows:uint = Math.ceil(gameHeight/pixelSize);
			var col:uint = 0;
			var row:uint = 0;
			
			for (var i:uint=0; i<cols*rows; i++) {
				points.push(new Point(col, row));
				col ++;
				if (col >= cols) {
					row ++;
					col = 0;
				}
			}
		}
	}
}