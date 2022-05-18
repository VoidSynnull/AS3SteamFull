/**
 * Parses XML with scene data.
 */

package game.data.scene
{
	import flash.utils.Dictionary;

	import game.data.ads.AdvertisingConstants;
	import game.data.game.GameEvent;
	import game.data.scene.hit.HitType;
	import game.data.scene.labels.LabelParser;
	import game.systems.scene.DoorSystem;
	import game.util.DataUtils;

	public class DoorParser
	{
		public function parse(xml:*, connector:Boolean = false):Dictionary
		{
			var data:Dictionary = new Dictionary(true);
			var doors:XMLList;

			if(xml is XMLList)
			{
				doors = xml;
			}
			else
			{
				doors = xml.children();
			}

			var doorData:DoorData;
			var doorXML:XML;
			var labelParser:LabelParser;

			for (var i:uint = 0; i < doors.length(); i++)
			{
				doorXML = doors[i];
				doorData = parseDoor(doorXML);

				if(data[doorData.id] == null && !connector)
				{
					data[doorData.id] = new Dictionary(true);
				}

				if(connector)
				{
					data[doorData.id] = doorData;
				}
				else
				{
					data[doorData.id][doorData.event] = doorData;
				}

				if(doorXML.hasOwnProperty("label"))
				{
					if(labelParser == null)
					{
						labelParser = new LabelParser();
					}

					doorData.label = labelParser.parse(XML(doorXML.label));
					doorData.label.text = doorData.label.text.toUpperCase();	// Note :: For Pop we want all door labels to be upper case
				}

				if(doorXML.hasOwnProperty("connectingSceneDoors"))
				{
					doorData.connectingSceneDoors = parse(doorXML.connectingSceneDoors.door, true);
				}
			}

			return(data);
		}

		public function parseDoor(doorXML:*):DoorData
		{
			var doorData:DoorData = new DoorData();
			doorData.id = DataUtils.getString(doorXML.attribute("id"));
			doorData.campaignName = DataUtils.getString(doorXML.attribute("campaignName"));
			doorData.destinationScene = DataUtils.getString(doorXML.scene);
			doorData.destinationSceneX = DataUtils.getNumber(doorXML.x);
			doorData.destinationSceneY = DataUtils.getNumber(doorXML.y);

			// ad stuff (if global AS2 scene or scene has delimiter or previousScene)
			var dest:String = doorData.destinationScene;
			doorData.adDoor = ((dest.indexOf("Global") != -1) || (dest.indexOf(AdvertisingConstants.CAMPAIGN_SCENE_DELIMITER) != -1) || (dest = DoorSystem.PREVIOUS_SCENE));

			if(doorXML.hasOwnProperty("minDistance"))
			{
				doorData.minDistanceX = DataUtils.getNumber(doorXML.minDistance.x);
				doorData.minDistanceY = DataUtils.getNumber(doorXML.minDistance.y);
			}
			if(doorXML.hasOwnProperty("multiplayer"))
			{
				doorData.multiplayer = DataUtils.getBoolean(doorXML.multiplayer);
			}
			doorData.destinationSceneDirection = DataUtils.getString(doorXML.direction);
			doorData.type = HitType.DOOR;
			doorData.openOnHit = DataUtils.getBoolean(doorXML.openOnHit);
			doorData.event = DataUtils.useString(doorXML.attribute("event"), GameEvent.DEFAULT);
			doorData.triggeredByEvent = DataUtils.getString(doorXML.attribute("triggeredByEvent"));

			return(doorData);
		}
	}
}
