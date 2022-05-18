/**
 * Parses XML with scene data.
 */

package game.data.scene.hit
{	
	import game.util.DataUtils;
	
	public class HazardHitParser
	{				
		public function parse(xml:XML):HazardHitData
		{		
			var data:HazardHitData = new HazardHitData();
			
			data.knockBackVelocity = DataUtils.getPoint(xml.knockBackVelocity[0] as XML);
			data.knockBackCoolDown = DataUtils.useNumber(xml.knockBackCooldown, .5);
			data.knockBackInterval = DataUtils.useNumber(xml.knockBackInterval, 0);
			data.velocityByHitAngle = DataUtils.useBoolean(xml.velocityByHitAngle, false);
			
			return(data);
		}
	}
}