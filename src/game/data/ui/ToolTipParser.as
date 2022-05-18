package game.data.ui
{
	import flash.utils.Dictionary;
	
	import game.util.DataUtils;

	public class ToolTipParser
	{
		public function parse(xml:XML):Dictionary
		{
			var data:Dictionary = new Dictionary();
			var toolTipXML:XMLList = xml.children();
			var toolTipData:ToolTipData;
			
			// create all npcs CharacterData within scene
			for (var i:uint = 0; i < toolTipXML.length(); i++)
			{	
				toolTipData = parseToolTip( toolTipXML[i] );
				
				data[toolTipData.type] = toolTipData;
			}
			
			return(data);
		}
		
		public function parseToolTip(xml:XML):ToolTipData
		{
			var toolTipData:ToolTipData = new ToolTipData();
			
			toolTipData.type = DataUtils.getString(xml.type);
			toolTipData.asset = DataUtils.getString(xml.asset);
			toolTipData.hotSpot = DataUtils.getPoint(xml.hotSpot[0]);
			toolTipData.transparentOnUp = DataUtils.getBoolean(xml.transparentOnUp);
			toolTipData.nativeCursor = DataUtils.getBoolean(xml.nativeCursor);
			toolTipData.dynamic = DataUtils.getBoolean(xml.dynamic);
			
			return(toolTipData);
		}
	}
}