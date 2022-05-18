/**
 * Parses XML with scene data.
 */

package game.data.scene.hit
{	
	import flash.geom.Point;
	import game.util.DataUtils;
	
	public class MovingHitParser
	{				
		public function parse(xml:XML):MovingHitData
		{		
			var data:MovingHitData = new MovingHitData();
			var points:XMLList;
			var pointXML:XML;
			
			data.velocity = DataUtils.getNumber(xml.velocity);
			data.pointIndex = 0;
			data.points = new Array();
			data.visible = DataUtils.getString(xml.visible);
			data.loop = DataUtils.useBoolean(xml.loop, true);
			data.teleportToStart = DataUtils.useBoolean(xml.teleportToStart, false);
			data.pause = DataUtils.useBoolean(xml.pause, false);
			points = xml.points.children() as XMLList;
			
			for (var n:uint = 0; n < points.length(); n++)
			{	
				pointXML = points[n];
				data.points.push(new Point(DataUtils.getNumber(pointXML.x), DataUtils.getNumber(pointXML.y)));
			}

			return(data);
		}
	}
}