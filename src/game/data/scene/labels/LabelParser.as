/**
 * Parses XML with label data.
 */

package game.data.scene.labels
{		
	import game.data.ui.ToolTipType;
	import game.util.DataUtils;
	
	public class LabelParser
	{				
		public function parse(xml:XML):LabelData
		{		
			var data:LabelData;
			
			data = new LabelData();
			data.id = DataUtils.getString(xml.id);
			data.x = DataUtils.getNumber(xml.x);
			data.y = DataUtils.getNumber(xml.y);
			data.text = DataUtils.useString(String(xml.text).toUpperCase(), ""); 
			data.type =  DataUtils.useString(xml.type, ToolTipType.CLICK);
			
			if(xml.hasOwnProperty("offset"))
			{
				data.offset = DataUtils.getPoint(xml.offset[0]);
			}
			
			return(data);
		}
	}
	
}