package game.scenes.examples.tiledScene.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class TilesData extends Component
	{
		//public function TilesData($tileData:Vector.<Vector.<Vector.<int>>>, $zeroPoint:Point, $topUp:Boolean = false){
		public function TilesData(){
			//tileData = $tileData;
			//zeroPoint = $zeroPoint;
			//topUp = $topUp;
		}
		
		public function randomizeBuilding():void{
			// creates a randomized building data structure
			for(var c:int = 0; c < tileData2D[0].length; c++){
				var rand:int = Math.round(Math.random()*3);
				for(var d:int = 1; d <= 3; d++){
					if(d-1 >= rand){
						tileData2D[d][c] = 1;
					} else {
						tileData2D[d][c] = 0;
					}
				}
			}
			refresh = true;
		}
		
		public var tileData2D:Array = 
			[[0,0,1,1,1,0,0,0],
			 [0,0,1,1,1,1,1,0],
			 [1,1,1,1,1,1,1,0],
			 [1,1,1,1,1,1,1,1]];
		
		public var cellWidth:Number = 100;
		public var cellHeight:Number = 100;
		public var tileData:Vector.<Vector.<Vector.<int>>>; // 3D Vector to store map data
		public var topUp:Boolean; // data should be mapped from the top up
		public var zeroPoint:Point; // 0,0 point of the tilesObject in the scene
		public var refresh:Boolean = false;
	}
}