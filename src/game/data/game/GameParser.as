/**
 * Parses XML with game data.
 */

package game.data.game
{	
	import game.util.DataUtils;
	
	public class GameParser
	{				
		public function parse(xml:XML):GameData
		{		
			var data:GameData = new GameData();

			data.islands = DataUtils.getArray(xml.islands);
			data.firstScene = DataUtils.getString(xml.firstScene);
			data.defaultScene = DataUtils.getString(xml.defaultScene);
			data.overrideScene = DataUtils.getString(xml.overrideScene);
			data.autoLoadFirstScene = DataUtils.getBoolean(xml.autoLoadFirstScene);
			
			return(data);
		}
	}
}