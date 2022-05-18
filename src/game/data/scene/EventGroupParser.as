/**
 * Parses XML with scene data.
 */

package game.data.scene
{	
	import flash.utils.Dictionary;
	import game.util.DataUtils;
	
	public class EventGroupParser
	{				
		public function parse(xml:XML):Dictionary
		{					
			var data:Dictionary = new Dictionary(true);
			var groups:XMLList = xml.children();
			var group:EventGroupData;
			var groupXML:XML;
			
			for (var i:uint = 0; i < groups.length(); i++)
			{	
				groupXML = groups[i];
				group = new EventGroupData();
				group.event = DataUtils.getString(groupXML.attribute("event"));
				group.triggerAndSave = DataUtils.getBoolean(groupXML.attribute("triggerAndSave"));
				group.onlyTrigger = DataUtils.getBoolean(groupXML.attribute("onlyTrigger"));
				
				group.conditions = parseGroupElements(groupXML.children())[0];

				data[group.event] = group;
			}
			
			return(data);
		}
		
		private function parseGroupElements(elements:XMLList):Vector.<ConditionData>
		{
			var condition:ConditionData;
			var elementXML:XML;
			var conditions:Vector.<ConditionData> = new Vector.<ConditionData>();
			
			for (var i:uint = 0; i < elements.length(); i++)
			{	
				elementXML = elements[i];
				
				condition = new ConditionData();
				condition.type = DataUtils.getString(elementXML.name());
				
				if (condition.type == EVENT)
				{
					condition.event = DataUtils.getString(elementXML.attribute("type"));
					condition.not = DataUtils.getBoolean(elementXML.attribute("not"));
				}
				else
				{
					condition.conditions = parseGroupElements(elements[i].children());
				}
				
				conditions.push(condition);
			}
			
			return(conditions);
		}
		
		public static var AND:String = "and";
		public static var OR:String = "or";
		public static var EVENT:String = "event";
	}
}