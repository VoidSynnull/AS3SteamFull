package game.scene.template.ads
{
	public class AdHotSpotParser
	{
		/**
		 * Parse hotspot.xml into data object 
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
			var vHotSpotNodes:XMLList = xml.children();
			var vHotSpotSubNodes:XMLList;
			var vHotSpotXML:XML;
			var vID:String;
			var vType:String;
			var vHotSpotSubXML:XML;
			var vSubObject:Object;
			
			// for each node
			for (var i:uint = 0; i < vHotSpotNodes.length(); i++)
			{	
				vHotSpotXML = vHotSpotNodes[i];
				vID = String(vHotSpotXML.attribute("id"));				
				vType = String(vHotSpotXML.attribute("type"));
				
				// if no type then show alert
				if ((vType == null) || (vType == ""))
					trace("AdHotSpotParser :: Missing Hot Spot Type Value!");
				
				vHotSpotSubNodes = vHotSpotXML.children();
				vSubObject = {};
				vSubObject.type = vType;
				
				// if video
				if (vID.toLowerCase().indexOf("video") != -1)
				{
					// get width and height or like, if any
					var vWidth:String = vHotSpotXML.attribute("width");
					if ((vWidth != null) && (vWidth != ""))
						vSubObject.width = vWidth;
					var vHeight:String = vHotSpotXML.attribute("height");
					if ((vHeight != null) && (vHeight != ""))
						vSubObject.height = vHeight;
					var locked:String = vHotSpotXML.attribute("locked");
					if ((locked != null) && (locked == "true"))
						vSubObject.locked = true;
					var controls:String = vHotSpotXML.attribute("controls");
					if ((controls != null) && (controls == "true"))
						vSubObject.controls = true;
					else {
						vSubObject.controls = false;
					}
					var suppressSponsorButton:String = vHotSpotXML.attribute("suppressSponsorButton");
					if ((suppressSponsorButton != null) && (suppressSponsorButton == "true"))
						vSubObject.suppressSponsorButton = true;
					vSubObject.fullscreen = (vHotSpotXML.attribute("fullscreen") == "true");
					vSubObject.game = vHotSpotXML.attribute("game");
					var showLikeButton:String = vHotSpotXML.attribute("showLikeButton");
					if ((showLikeButton != null) && (showLikeButton == "true"))
						vSubObject.showLikeButton = true;
					var endScreensText:String = vHotSpotXML.attribute("endScreens");
					if (endScreensText != null)
						vSubObject.endScreensText = endScreensText;
				}
				
				// for each subnode
				for (var j:uint = 0; j < vHotSpotSubNodes.length(); j++)
				{	
					vHotSpotSubXML = vHotSpotSubNodes[j];
					// convert xml type/value to key/value on sub object
					vSubObject[String(vHotSpotSubXML.attribute("type"))] = String(vHotSpotSubXML.valueOf());
				}
				// attach sub object to data object with ID key
				vData[vID] = vSubObject;
			}
			return(vData);
		}
	}
}