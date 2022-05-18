package game.data.character
{
	import game.util.DataUtils;

	public class DrawLimbParser
	{
		public function parseSet(xml:XML):DrawLimbSet
		{
			var limbs:XMLList = xml.children();
			var limbSet:DrawLimbSet = new DrawLimbSet();
			
			var limbXml:XML;
			var limbData:DrawLimbData;
			
			for( var number:uint = 0; number < limbs.length(); number ++ )
			{
				limbXml = XML( limbs[ number ]);
				limbData = new DrawLimbData();
				
				limbData.joint 			= DataUtils.getString( limbXml.part );
				limbData.leader			= DataUtils.getString( limbXml.leader );
				limbData.lineWidth 		= DataUtils.getNumber( limbXml.lineWidth );
				limbData.maxDist 		= DataUtils.getNumber( limbXml.maxDist );
				limbData.offset 		= DataUtils.getNumber( limbXml.offset );
				limbData.isBendForward 	= DataUtils.getBoolean( limbXml.isBendForward );

				limbSet.limbs.push( limbData );				
			}
			
			return limbSet;
		}
	}
}