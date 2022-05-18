package game.scenes.hub.balloons.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	public class BalloonsGrid extends Component
	{
		public static const COLUMN_NUM:int 				= 5;
		public static const ROW_NUM:int					= 4;
		
		public function BalloonsGrid($entity:Entity)
		{
			super();
			
			var gridSpatial:Spatial = $entity.get(Spatial);
			var cellWidth:Number = gridSpatial.width / COLUMN_NUM;
			var cellHeight:Number = gridSpatial.height / ROW_NUM;
			
			// build data based off of the grid entity
			for(var c:int = 0; c < COLUMN_NUM; c++){
				data[c] = new Vector.<BalloonCell>( ROW_NUM );
				for(var r:int = 0; r < ROW_NUM; r++){
					var coords:Point = new Point();
					coords.x = gridSpatial.x + ( cellWidth / 2 ) + ( cellWidth * c );
					coords.y = gridSpatial.y + ( cellHeight / 2 ) + ( cellHeight * r );
					data[c][r] = new BalloonCell( c, r, coords );
				}
			}
		}
		
		public var data:Vector.<Vector.<BalloonCell>> = new Vector.<Vector.<BalloonCell>>( COLUMN_NUM );
	}
}