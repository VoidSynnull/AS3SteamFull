package game.scenes.examples.tiledScene.systems
{
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.scenes.examples.tiledScene.nodes.TilesNode;
	
	public class TilesSystem extends ListIteratingSystem
	{
		public function TilesSystem($group:Group)
		{
			_group = $group;
			super(TilesNode, updateNode);
		}
		
		private function updateNode($node:TilesNode, $time:Number):void{
			_entity = _group.getEntityById("tiles");
			_display = Display(_entity.get(Display)).displayObject as MovieClip;
			_node = $node;
			
			if($node.tilesData.tileData2D != null){
				if(_tileData != $node.tilesData.tileData2D || $node.tilesData.refresh == true){
					$node.tilesData.refresh = false;
					_tileData = $node.tilesData.tileData2D;
					
					
					// add center tile to every 1 on the map
					for(var c:int = 0; c < _tileData.length; c++){
						for(var d:int = 0; d < _tileData[c].length; d++){
							if(_tileData[c][d] == 1){
								var bitmap:Bitmap = new Bitmap($node.tilesAsset.tileAssetGrid[0][1][1].bitmapData);
								bitmap.x = d * $node.tilesData.cellWidth;
								bitmap.y = c * $node.tilesData.cellHeight;
								_display.addChild(bitmap);
								addRandomDetail(1, 1, bitmap.x, bitmap.y);
								
								var bottom:Boolean = false;
								var top:Boolean = false;
								var left:Boolean = false;
								var right:Boolean = false;
								
								//check bottom
								if(c == _tileData.length - 1){
									addBottomEdge(c,d);
									bottom = true;
								}
								
								//check top
								if(c == 0){
									addTopEdge(c,d);
									top = true;
								} else if(_tileData[c-1][d] == 0){
									addTopEdge(c,d);
									top = true;
								}
								
								//check left
								if(d == 0){
									addLeftEdge(c,d);
									left = true;
								} else if(_tileData[c][d-1] == 0){
									addLeftEdge(c,d);
									left = true;
								}
								
								//check right
								if(d+1 == _tileData[c].length){
									addRightEdge(c,d);
									right = true;
								} else if(_tileData[c][d+1] == 0){
									addRightEdge(c,d);
									right = true;
								}
								
								if(left == true && top == true){
									addUpperLeftEdge(c,d);
								}
								
								if(left == true && bottom == true){
									addLowerLeftEdge(c,d);
								}
								
								if(right == true && top == true){
									addUpperRightEdge(c,d);
								}
								
								if(right == true && bottom == true){
									addLowerRightEdge(c,d);
								}
							}
						}
					}
				}
			} else {
				//trace("null");
			}
		}
		
		private function addBottomEdge($c:int, $d:int):void{
			var bottomBitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][2][1].bitmapData);
			bottomBitmap.x = $d * _node.tilesData.cellWidth;
			bottomBitmap.y = ($c+1) * _node.tilesData.cellHeight;
			_display.addChild(bottomBitmap);
			addRandomDetail(2, 1, bottomBitmap.x, bottomBitmap.y);
		}
		
		private function addTopEdge($c:int, $d:int):void{
			var topBitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][0][1].bitmapData);
			topBitmap.x = $d * _node.tilesData.cellWidth;
			topBitmap.y = ($c-1) * _node.tilesData.cellHeight;
			_display.addChild(topBitmap);
			addRandomDetail(0, 1, topBitmap.x, topBitmap.y);
		}
		
		private function addLeftEdge($c:int, $d:int):void{
			var leftBitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][1][0].bitmapData);
			leftBitmap.x = ($d-1) * _node.tilesData.cellWidth;
			leftBitmap.y = $c * _node.tilesData.cellHeight;
			_display.addChild(leftBitmap);
			addRandomDetail(1, 0, leftBitmap.x, leftBitmap.y);
		}
		
		private function addRightEdge($c:int, $d:int):void{
			var rightBitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][1][2].bitmapData);
			rightBitmap.x = ($d+1) * _node.tilesData.cellWidth;
			rightBitmap.y = $c * _node.tilesData.cellHeight;
			_display.addChild(rightBitmap);
			addRandomDetail(1, 2, rightBitmap.x, rightBitmap.y);
		}
		
		private function addUpperLeftEdge($c:int, $d:int):void{
			var bitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][0][0].bitmapData);
			bitmap.x = ($d-1) * _node.tilesData.cellWidth;
			bitmap.y = ($c-1) * _node.tilesData.cellHeight;
			_display.addChild(bitmap);
			addRandomDetail(0, 0, bitmap.x, bitmap.y);
		}
		
		private function addLowerLeftEdge($c:int, $d:int):void{
			var bitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][2][0].bitmapData);
			bitmap.x = ($d-1) * _node.tilesData.cellWidth;
			bitmap.y = ($c+1) * _node.tilesData.cellHeight;
			_display.addChild(bitmap);
			addRandomDetail(2, 0, bitmap.x, bitmap.y);
		}
		
		private function addUpperRightEdge($c:int, $d:int):void{
			var bitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][0][2].bitmapData);
			bitmap.x = ($d+1) * _node.tilesData.cellWidth;
			bitmap.y = ($c-1) * _node.tilesData.cellHeight;
			_display.addChild(bitmap);
			addRandomDetail(0, 2, bitmap.x, bitmap.y);
		}
		
		private function addLowerRightEdge($c:int, $d:int):void{
			var bitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[0][2][2].bitmapData);
			bitmap.x = ($d+1) * _node.tilesData.cellWidth;
			bitmap.y = ($c+1) * _node.tilesData.cellHeight;
			_display.addChild(bitmap);
			addRandomDetail(2, 2, bitmap.x, bitmap.y);
		}
		
		private function addRandomDetail($a:int, $b:int, $x:Number, $y:Number, $force:Boolean = false):void{
			for(var c:int = 0; c < _node.tilesAsset.tileAssetGrid.length; c++){
				if(Math.random() > 0.5 || $force == true){
					var bitmap:Bitmap = new Bitmap(_node.tilesAsset.tileAssetGrid[c][$a][$b].bitmapData);
					bitmap.x = $x;
					bitmap.y = $y;
					_display.addChild(bitmap);
				}
			}
		}
		
		private var _group:Group;
		private var _tileData:Array;
		
		private var _node:TilesNode;
		private var _entity:Entity;
		private var _display:MovieClip;
	}
}