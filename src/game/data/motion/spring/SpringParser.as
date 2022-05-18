/**
 * Parses XML with skin data.
 */

package game.data.motion.spring
{	

	import game.util.DataUtils;

	public class SpringParser
	{	
		public function parseSet( xml:XML ):SpringSet
		{
			var springs:XMLList = xml.children();
			var springSet:SpringSet = new SpringSet;
			
			var springXml:XML;
			var springData:SpringData;

			for (var i:uint = 0; i < springs.length(); i++)
			{	
				springXml 	= XML( springs[i] );
				springData 	= new SpringData();
			
				springData.joint 			= DataUtils.getString(springXml.part);
				springData.leader 			= DataUtils.getString(springXml.leader);
				springData.spring 			= DataUtils.getNumber(springXml.spring);
				springData.damp 			= DataUtils.getNumber(springXml.damp);
				springData.rotateByLeader 	= DataUtils.getBoolean(springXml.rotateByLeader);
				springData.rotateByVelocity = DataUtils.getBoolean(springXml.rotateByVelocity);
				springData.rotateRatio 		= DataUtils.getNumber(springXml.rotateRatio);
				springData.offsetX 			= DataUtils.getNumber(springXml.offsetX);
				springData.offsetY 			= DataUtils.getNumber(springXml.offsetY);
			
				springSet.springs.push( springData );
			}
			return springSet;
		}
	}
}