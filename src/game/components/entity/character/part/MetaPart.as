package game.components.entity.character.part
{	
	import ash.core.Component;
	
	import game.data.character.part.PartMetaData;
	
	public class MetaPart extends Component
	{
		public function MetaPart( id:String = "", type:String = "", assetPath:String = null, dataPath:String = null )
		{
			this.id = id;
			this.type = type;
			this.assetPath = assetPath;
			this.dataPath = dataPath;
		}
		
		public var id : String;						// id for specific part (e.g. arm1, hand2, foot2, facial, shirt, bodySkin )
		public var type : String;					// part type, used to retrieve assest (e.g. hand, foot, facial, shirt, bodySkin )
		public var assetPath : String;				// asset path
		public var dataPath : String;				// data path
		public var hasPart : Boolean = true;		// if MetaPart is associated with a Part component (skinColor, hairColor, eyeState are not)
		public var replace:Boolean = false;			// flag signalling that next data should replace 
	
		public var currentData:PartMetaData;		// current MetaData
		public var nextData:PartMetaData;			// MetaData to be applied
	}
}
