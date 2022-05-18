/**
 * Parses XML with item data.
 */

package game.data.item
{	
	import flash.utils.Dictionary;
	
	import game.data.game.GameEvent;
	import game.data.item.SceneItemData;
	import game.data.scene.labels.LabelData;
	import game.data.scene.labels.LabelParser;
	import game.data.ui.ToolTipType;
	import game.util.DataUtils;
	
	public class SceneItemParser
	{				
		public function parse(xml:XML):Dictionary
		{		
			var data:Dictionary = new Dictionary(true);
			var items:XMLList = xml.children();
			var sceneItemData:SceneItemData;
			var sceneItemXML:XML;
			var labelParser:LabelParser;
			
			for (var i:uint = 0; i < items.length(); i++)
			{	
				sceneItemXML = items[i];
				sceneItemData = new SceneItemData();
				sceneItemData.id = DataUtils.getString(sceneItemXML.id);
				sceneItemData.collection = DataUtils.getString(sceneItemXML.collection);
				sceneItemData.asset = DataUtils.getString(sceneItemXML.asset);
				sceneItemData.x = DataUtils.getNumber(sceneItemXML.x);
				sceneItemData.y = DataUtils.getNumber(sceneItemXML.y);
				sceneItemData.rotation = DataUtils.useNumber(sceneItemXML.rotation, 0);
				sceneItemData.event = DataUtils.useString(sceneItemXML.attribute("event"), GameEvent.DEFAULT);
				sceneItemData.triggeredByEvent = DataUtils.getString(sceneItemXML.attribute("triggeredByEvent"));

				data[sceneItemData.id] = sceneItemData;
				
				if(sceneItemXML.hasOwnProperty("label"))
				{
					if(labelParser == null)
					{
						labelParser = new LabelParser();
					}
					
					sceneItemData.label = labelParser.parse(XML(sceneItemXML.label));
					// if 'examine' remove for now
					if(sceneItemData.label.text == EXAMINE ) 
					{
						sceneItemData.label.text = "";
					}
				}else{
					sceneItemData.label = new LabelData(ToolTipType.CLICK, "");
				}
			}

			return(data);
		}
		
		private const EXAMINE: String = "EXAMINE";
	}
}

/*
<item id="crowbar">
<name>Crow Bar</name>
<type>UseableItem</type>
<button event='itemUse'>USE</button>
</item>
*/