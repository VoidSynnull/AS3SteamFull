/**
 * Parses XML with item data.
 */

package game.data.item
{	
	import game.util.DataUtils;
	
	public class ItemParser
	{				
		public function parse(xml:XML):ItemData
		{		
			var data:ItemData = new ItemData();
			
			data.id = DataUtils.getString(xml.attribute("id"));
			data.name =  DataUtils.getString(xml.name);
			data.type =  DataUtils.getString(xml.type);
			data.event = DataUtils.getString(xml.button.@event);
			// to do: handle items w/ multiple buttons?
			//data.buttons = new Vector<ButtonData>;
			
			var s:String = DataUtils.getString(xml.button.@eventArgs)
			if (s) {
			data.eventArgs = new Vector.<String>
				var a:Array = s.split (",")
				for each (var st:String in a) {
					data.eventArgs.push (st)
				}
			}
			return(data);
		}
	}
	
}

/*
<item id="crowbar">
<name>Crow Bar</name>
<type>UseableItem</type>
<button event='itemUse'>USE</button>
</item>
*/