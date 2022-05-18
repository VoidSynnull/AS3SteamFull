/**
 * Parses XML with scene data.
 */

package game.data.scene.hit
{	
	import game.util.DataUtils;
	
	public class WaterHitParser
	{				
		public function parse(xml:XML):WaterHitData
		{		
			var data:WaterHitData = new WaterHitData();
						
			data.splashColor1 = DataUtils.getNumber(xml.splashColor1);
			data.splashColor2 = DataUtils.getNumber(xml.splashColor2);
			
			if( xml.hasOwnProperty( "density" ) )
			{
				data.density = DataUtils.getNumber( xml.density );
			}
			if( xml.hasOwnProperty( "viscosity" ) )
			{
				data.viscosity = DataUtils.getNumber( xml.viscosity );
			}
			if( xml.hasOwnProperty( "sceneWide" ) )
			{
				data.sceneWide = DataUtils.getBoolean( xml.sceneWide );
			}
			
			return(data);
		}
	}
}