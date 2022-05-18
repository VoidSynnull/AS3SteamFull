package game.data.character.part
{
	import flash.utils.Dictionary;
	
	import game.util.DataUtils;

	public class PartKeyLibrary
	{
		public function PartKeyLibrary()
		{
			_partKeys = new Dictionary();
		}
		
		/**
		 * Checks to see if part value is a Number with a matching label.
		 * If matching label is found the label is returned, otherwise initial value is returned.
		 */
		public function checkForLabel( partType:String, value:* ):*
		{
			var frameIndex:Number = Number( value );
			if( isNaN( frameIndex ) )
			{
				//trace( " PartKeyLibrary : checkForLabel : value " + value + " isNaN." );
				return value;
			}
			else
			{
				var label:String = String( getLabelByIndex( partType, frameIndex ) );
				if( DataUtils.validString( label ) )
				{
					label = label.toLowerCase();
					trace( " PartKeyLibrary : checkForLabel : value " + frameIndex + " converted to " + label );
					return label;
				}
				else
				{
					//trace( " PartKeyLibrary : checkForLabel : value " + value + " no label found." );
					return value;
				}
			}
		}
		
		public function getLabelByIndex( partType:String, frameIndex:int ):String
		{
			var partKeyDict:Dictionary = _partKeys[ partType ];
			if( partKeyDict )
			{
				return partKeyDict[frameIndex];
			}
			else
			{
				trace( "Error :: PartKeyLibrary :: getLabel :: Key Dictionary for part type " + partType + " does not exist." );
				return "";
			}
		}
		
		/**
		 * Instantiate animation class, loads xml, and adds to Dictionary if not yet added.
		 * Animation classes are shared across all entities that use this system
		 * @param	animationClass
		 * @param	type
		 */
		public function addKeySet( partType:String, xml:XML ):void
		{
			var partKeyDict:Dictionary = new Dictionary();
			_partKeys[ partType ] = partKeyDict;
			
			var partList:XMLList = xml.children();
			var partXML:XML;
			var frame:int;
			var label:String;
			
			var numParts:int = partList.length();
			for (var i:int = 0; i < numParts; i++) 
			{
				partXML = partList[i];
				frame = partXML.attribute("frame");
				label = DataUtils.getString( partXML );
				partKeyDict[ frame ] = label;
			}
		}

		private var _partKeys:Dictionary;
	}
}