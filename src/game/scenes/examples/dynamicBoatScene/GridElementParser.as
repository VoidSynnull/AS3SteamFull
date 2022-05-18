package game.scenes.examples.dynamicBoatScene
{
	import game.data.scene.DoorData;
	import game.data.scene.DoorParser;
	import game.util.DataUtils;

	public class GridElementParser
	{
		public function GridElementParser()
		{
		}
		
		public function parse(xml:XML):Vector.<GridElementData>
		{		
			var elements:Vector.<GridElementData> = new Vector.<GridElementData>();
			var elementXMLs:XMLList = xml.children() as XMLList;
			var elementXML:XML;
			var element:GridElementData;
			var doorParser:DoorParser = new DoorParser();
			
			for (var i:uint = 0; i < elementXMLs.length(); i++)
			{	
				elementXML = elementXMLs[i];
				
				element = new GridElementData();
				element.id = DataUtils.getString(elementXML.attribute("id"));
				element.url = DataUtils.getString(elementXML.display.url);
				element.bitmap = DataUtils.getBoolean(elementXML.display.bitmap);
				element.x = DataUtils.getNumber(elementXML.position.x);
				element.y = DataUtils.getNumber(elementXML.position.y);
				
				if(elementXML.hasOwnProperty("door"))
				{
					element.door = doorParser.parseDoor(elementXML.door);
				}
				
				elements.push(element);
			}
			
			return(elements);
		}
	}
}