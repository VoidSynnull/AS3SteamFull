/**
 * Parses XML with scene data.
 */

package game.data.scene.hit
{	
	import game.util.DataUtils;
	
	public class LooperHitParser
	{				
		public function parse( looperXML:XML ):LooperHitData
		{		
			var data:LooperHitData = new LooperHitData();
			
			data.motionRate = DataUtils.useNumber( looperXML.motionRate, 1 );
			data.visualHeight = DataUtils.useNumber( looperXML.visualHeight, NaN );
			data.visualWidth = DataUtils.useNumber( looperXML.visualWidth, NaN );
			data.event = DataUtils.useString( looperXML.event, null );
			data.lastObject = DataUtils.useBoolean(looperXML.lastObject,false);
			
			if( data.event )
			{
				data.active = false;
			}
			return( data );
		}
	}
}