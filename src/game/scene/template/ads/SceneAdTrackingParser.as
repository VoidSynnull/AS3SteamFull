package game.scene.template.ads
{
	public class SceneAdTrackingParser
	{
		public function SceneAdTrackingParser():void
		{
		}
		
		static public function parse(xml:XML):Object
		{
			var vTrackNode:XMLList = xml.children();
			var vTrackSubNode:XMLList;
			var vTrackXML:XML;
			var vID:String;
			var vTrackSubXML:XML;
			var vData:Object = {};
			var vSubObject:Object;
			
			for (var i:uint = 0; i < vTrackNode.length(); i++)
			{	
				vTrackXML = vTrackNode[i];
				vID = String(vTrackXML.attribute("id"));
				vTrackSubNode = vTrackXML.children();
				vSubObject = {};
				for (var j:uint = 0; j < vTrackSubNode.length(); j++)
				{	
					vTrackSubXML = vTrackSubNode[j];
					vSubObject[String(vTrackSubXML.name())] = String(vTrackSubXML.valueOf());
				}
				vData[vID] = vSubObject;
			}
			return(vData);
		}
	}
}