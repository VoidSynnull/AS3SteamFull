package game.scenes.shrink.carGame.parsers
{
	import game.scenes.shrink.carGame.hitData.ObstacleData;
	import game.scenes.shrink.carGame.hitData.SegmentData;
	import game.util.DataUtils;

	public class SegmentParser
	{
		/**
		 * Parse <code>XML</code> into <code>SegmentData</code>.
		 * 
		 * @param segmentXML - <code>XML</code> to be parsed for <code>ObstacleData</code>.
		 * @return <code>SegmentData</code> containing the art <code>String</code> and a <code>Vector</code> of the obstacles that will need to be created as <code>Entities</code> with a display.
		 */ 
		public static function parse( segmentXML:XML ):SegmentData
		{
			var data:SegmentData 		=	new SegmentData();
			var obstacles:XMLList 		=	segmentXML.obstacles;
			
			data.backgroundClip 		= 	segmentXML.background;
			data.event 					=	segmentXML.event;
			if( obstacles.length() > 0 )
			{
				data.obstacles 			=	parseObstacles( obstacles.children());
			}
			
			return( data );
		}
		
		/**
		 * Parse <code>XMLList</code> of obstacles to be added to the moving segment.
		 * 
		 * @param obstaclesXML - <code>XMLList</code> containing data about the obstacle locations, type and artwork for this segment
		 * @return <code>Vector</code> of <code>ObstacleData</code> for this segment.
		 */
		public static function parseObstacles( obstaclesXML:XMLList ):Vector.<ObstacleData>
		{
			var obstaclesVector:Vector.<ObstacleData> = new Vector.<ObstacleData>;
			var obstacleXML:XML;
			var obstacleData:ObstacleData;
			
			for( var number:uint = 0; number < obstaclesXML.length(); number ++ )
			{
				obstacleData = new ObstacleData();
				obstacleXML = obstaclesXML[ number ][ 0 ];
				
				obstacleData.type = DataUtils.useString( obstacleXML.type, null );
				obstacleData.clipName = DataUtils.useString( obstacleXML.clip, null );
				obstacleData.x = DataUtils.useNumber( obstacleXML.x, NaN );
				obstacleData.y = DataUtils.useNumber( obstacleXML.y, NaN );
				
				obstaclesVector.push( obstacleData );
			}
			
			return( obstaclesVector );
		}
	}
}