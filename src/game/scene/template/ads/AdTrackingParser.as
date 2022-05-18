package game.scene.template.ads
{
	public class AdTrackingParser
	{
		/**
		 * parse tracking xml into data object 
		 * @param xml
		 * @return object
		 * 
		 */
		static public function parse(xml:XML):Object
		{
			// if no xml, then return empty object
			if (xml == null)
				return {};
			
			var vData:Object = {};
			var vTrackNodes:XMLList = xml.children();
			var vTrackSubNodes:XMLList;
			var vTrackXML:XML;
			var vID:String;
			var vTrackSubXML:XML;
			var vSubObject:Object;
			
			// for each node
			for (var i:uint = 0; i < vTrackNodes.length(); i++)
			{	
				vTrackXML = vTrackNodes[i];
				vID = String(vTrackXML.attribute("id"));
				vTrackSubNodes = vTrackXML.children();
				vSubObject = {};
				
				// for each subnode
				for (var j:uint = 0; j < vTrackSubNodes.length(); j++)
				{	
					vTrackSubXML = vTrackSubNodes[j];
					// convert xml name/value to key/value on sub object
					vSubObject[String(vTrackSubXML.name())] = String(vTrackSubXML.valueOf());
				}
				// attach sub object to data object with ID key
				vData[vID] = vSubObject;
			}
			return(vData);
		}
	}
}