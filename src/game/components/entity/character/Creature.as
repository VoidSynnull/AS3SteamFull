package game.components.entity.character
{
	import ash.core.Component;
	
	public class Creature extends Component
	{
		public var variant:String;
	
		public function Creature( variant:String = null )
		{
			this.variant = ( variant == null ) ? CREATURE : variant;
		}
		
		public static var APE:String 	  =			"ape";
		public static var BIPED:String	  =			"biped";
		public static var CREATURE:String = 		"creature";
		public static var PET_BABYQUAD:String = 	"pet_babyquad";
	}
}
