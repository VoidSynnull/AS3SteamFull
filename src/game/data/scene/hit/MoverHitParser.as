/**
 * Parses XML with scene data.
 */

package game.data.scene.hit
{	
	import game.util.DataUtils;
	
	public class MoverHitParser
	{				
		public function parse(xml:XML):MoverHitData
		{		
			var data:MoverHitData = new MoverHitData();

			if(xml.hasOwnProperty("velocity"))
			{
				data.velocity = DataUtils.getPoint(xml.velocity[0] as XML);
			}
			
			if(xml.hasOwnProperty("acceleration"))
			{
				data.acceleration = DataUtils.getPoint(xml.acceleration[0] as XML);
			}

			if(xml.hasOwnProperty("friction"))
			{
				data.friction = DataUtils.getPoint(xml.friction[0] as XML);
			}
			
			if(xml.hasOwnProperty("rotationVelocity"))
			{
				data.rotationVelocity = DataUtils.getNumber(xml.rotationVelocity[0] as XML);
			}
			
			if(xml.hasOwnProperty("stickToPlatforms"))
			{
				data.stickToPlatforms = DataUtils.getBoolean(xml.stickToPlatforms[0] as XML);
			}
			else
			{
				data.stickToPlatforms = false;
			}
			
			if(xml.hasOwnProperty("bounce"))
			{
				data.bounce = DataUtils.getNumber(xml.bounce[0] as XML);
			}
			else
			{
				data.bounce = 0;
			}
			
			if(xml.hasOwnProperty("overrideVelocity"))
			{
				data.overrideVelocity = DataUtils.getBoolean(xml.overrideVelocity[0] as XML);
			}
			else
			{
				data.overrideVelocity = false;
			}
			
			return(data);
		}
	}
}