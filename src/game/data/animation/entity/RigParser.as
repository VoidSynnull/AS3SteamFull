package game.data.animation.entity
{
	import game.data.character.LookData;
	import game.util.DataUtils;
	
	/**
	 * Parses rig XML into RigData, contains all parts correctly order with relevant data to construct a rig for animation.
	 */
	public class RigParser
	{
		/**
		 * Parse Xml into RigData.
		 * @param xml
		 * @return 
		 * 
		 */
		public function parse(xml:XML) : RigData
		{
			var rigData:RigData = new RigData();

			rigData.type = DataUtils.getString( xml.attribute("beingType") );
			rigData.assetPath = DataUtils.getString( xml.attribute("assetPath") );
			rigData.dataPath = DataUtils.getString( xml.attribute("dataPath") );
			
			// create PartDatas
			var parts:XMLList = XML( xml.children()[0] ).children();
			for ( var j:int = 0; j < parts.length(); j++)
			{
				var partXML:XML = parts[j];
				var partData : PartRigData = new PartRigData();
		
				partData.layer 				= j;		// currently layer order is just determined by xml order, could be specified as attribute though
				partData.id 				= DataUtils.getString( partXML.attribute("id") );
				
				if ( partXML.hasOwnProperty("joint") )
				{
					partData.jointId = DataUtils.getString( partXML.joint );
					partData.animDriven = DataUtils.getBoolean( partXML.joint.attribute("animDriven") );
					partData.ignoreRotation = DataUtils.getBoolean( partXML.joint.attribute("ignoreRotation") );
				}
				if ( partXML.hasOwnProperty("partType") )
				{
					partData.partType = DataUtils.getString( partXML.partType );
				}
				if ( partXML.hasOwnProperty("isGraphic") )
				{
					partData.isGraphic = DataUtils.getBoolean( partXML.isGraphic );
				}

				rigData.addPartData( partData );
			}
			
			return(rigData);
		}
		
		/**
		 * Parse Xml into RigData, excluding parts that do not have a corresponding look within passed LookData. 
		 * @param xml
		 * @param lookData
		 * @return 
		 */
		public function parseWithLook( xml:XML, lookData:LookData ) : RigData
		{
			var rigData:RigData = new RigData();
			
			rigData.type = DataUtils.getString( xml.attribute("beingType") );
			rigData.assetPath = DataUtils.getString( xml.attribute("assetPath") );
			rigData.dataPath = DataUtils.getString( xml.attribute("dataPath") );
			
			// create PartDatas
			var parts:XMLList = XML( xml.children()[0] ).children();
			for ( var j:int = 0; j < parts.length(); j++)
			{
				var partXML:XML = parts[j];
				var id:String = DataUtils.getString( partXML.attribute("id") );
				var isOptional:Boolean = DataUtils.getBoolean( partXML.attribute("optional") );
				
				if( isOptional && (lookData.getAspect( id ) == null) )	// if optional and no corresponding skin, don't create
				{
					continue;
				}
				else
				{
					var partData : PartRigData = new PartRigData();
					partData.layer 				= j;		// currently layer order is just determined by xml order, could be specified as attribute though
					partData.id 				= id;

					if ( partXML.hasOwnProperty("joint") )
					{
						partData.jointId = DataUtils.getString( partXML.joint );
						partData.animDriven = DataUtils.getBoolean( partXML.joint.attribute("animDriven") );
						partData.ignoreRotation = DataUtils.getBoolean( partXML.joint.attribute("ignoreRotation") );
					}
					if ( partXML.hasOwnProperty("partType") )
					{
						partData.partType = DataUtils.getString( partXML.partType );
					}
					if ( partXML.hasOwnProperty("isGraphic") )
					{
						partData.isGraphic = DataUtils.getBoolean( partXML.isGraphic );
					}
					
					rigData.addPartData( partData );
				}
			}
			
			return(rigData);
		}
	}
}