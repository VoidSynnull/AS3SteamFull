package game.scenes.examples.tiledScene.components
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class TilesAsset extends Component
	{
		public function TilesAsset($movieClip:MovieClip, $cellWidth:Number, $cellHeight:Number, $totalWidth:Number, $totalHeight:Number)
		{
			// init
			tileAssetGrid = new Vector.<Vector.<Vector.<Bitmap>>>;
			
			// separate layers
			displayObjects = new Vector.<Bitmap>;
			
			for(var c:int = 0; c < $movieClip.numChildren; c++){
				var bitmapData:BitmapData = new BitmapData($totalWidth, $totalHeight, true, 0x000000);
				var matrix:Matrix = new Matrix();
				matrix.tx = $movieClip.getChildAt(c).x;
				matrix.ty = $movieClip.getChildAt(c).y;
				bitmapData.draw($movieClip.getChildAt(c),matrix);
				displayObjects.push(new Bitmap(bitmapData));
			}
			// draw single bitmap
			// carve bitmap into 9grid 
			
			for(var d:int = 0; d < displayObjects.length; d++){
				tileAssetGrid.push(split9Grid(displayObjects[d], $cellWidth, $cellHeight));
			}
			
			//trace("tileAssetGrid:"+tileAssetGrid);
		}
		
		private function split9Grid($bitmap:Bitmap, $cellWidth:Number, $cellHeight:Number):Vector.<Vector.<Bitmap>>{
			// draw 9 cells from bitmapData
			
			var bitmaps:Vector.<Vector.<Bitmap>> = new Vector.<Vector.<Bitmap>>;
			
			for(var c:int = 0; c < 3; c++){
				bitmaps[c] = new Vector.<Bitmap>;
				for(var d:int = 0; d < 3; d++){
					var bitmapData:BitmapData = new BitmapData($cellWidth, $cellHeight, true, 0xFFFFFF);
					var rect:Rectangle = new Rectangle(d*$cellWidth, c*$cellHeight, $cellWidth, $cellHeight); 
					bitmapData.copyPixels($bitmap.bitmapData, rect, new Point(0,0));
					bitmaps[c][d] = new Bitmap(bitmapData);
				}
			}
			
			return bitmaps;
		}
		
		public var displayObjects:Vector.<Bitmap>;
		public var tileAssetGrid:Vector.<Vector.<Vector.<Bitmap>>>;
	}
}