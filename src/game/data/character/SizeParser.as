/**
 * Parses XML with npc data.
 * 
 * Npc's can have a unique setup for any game event.  If no event is specified in npcs.xml, they will
 * 	only ever use that single setup as DEFAULT.
 */

package game.data.character
{	
	import game.util.DataUtils;
	
	public class SizeParser
	{				 
		public function parse( sizeXml:XML ):SizeData
		{
			var sizeData:SizeData = new SizeData();
			
			if ( sizeXml.hasOwnProperty("scale") )
			{
				sizeData.scale = DataUtils.getNumber(sizeXml.scale)
			}
			
			if ( sizeXml.hasOwnProperty("dialogPosition") )
			{
				//var dialogPositionXml:XML = sizeXml.dialogPosition as XML;
				sizeData.dialogPositionPercent.x = DataUtils.getNumber(sizeXml.dialogPosition.attribute("xPercent"));
				sizeData.dialogPositionPercent.y = DataUtils.getNumber(sizeXml.dialogPosition.attribute("yPercent"));
			}

			if ( sizeXml.hasOwnProperty("edges") )
			{
				var edgesXmlList:XMLList = sizeXml.edges.children();
				var edgeXml:XML;
				var edgeData:EdgeData;
				
				for (var n:uint = 0; n < edgesXmlList.length(); n++)
				{
					edgeXml = edgesXmlList[n];
					edgeData = new EdgeData();
					
					edgeData.top =  DataUtils.getNumber(edgeXml.attribute("top"));
					edgeData.bottom =  DataUtils.getNumber(edgeXml.attribute("bottom"));
					edgeData.right =  DataUtils.getNumber(edgeXml.attribute("right"));
					edgeData.left =  DataUtils.getNumber(edgeXml.attribute("left"));
					
					edgeData.id =  DataUtils.getString(edgeXml.attribute("id"));
					sizeData.addEdgeData( edgeData );
				}
			}
			
			return sizeData;
		}
		
		
	}
}