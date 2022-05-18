package game.data.animation.entity
{
	public class PartRigData
	{	
		public var id : String;							// specific part type (e.g. arm1, facial, hand2, bodySkin, shirt)
		public var partType : String;					// types of part items ( e.g. facial, hand, bodySkin, shirt)
		public var layer : int;							// depth of part within character's display
		public var jointId : String;					// joint that the part is positioned by
		public var animDriven : Boolean = false;		// whether joint is driven by animation data
		public var ignoreRotation : Boolean = false;	// if joint should ignore rotation specified by animation (used in thecase of arm & leg joints)
		public var isGraphic : Boolean = false;			// whether part is a graphic drawn dynamically 
		
	}
}