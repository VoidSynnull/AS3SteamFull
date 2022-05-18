package game.data.specialAbility
{
	dynamic public class SpecialAbilityTypes
	{
		// We only need types for abilities attached to cards
		// This means that any class referenced in an ability xml file in the abilities folder should be included here
		// The constant name should match the short name of the ability class
		// NOTE: Some abilities use the same type so as to prevent similar abilities from existing simultaneously
		
		// If an ability is action chain only, then the type MUST be set in the xml
		// For action chains, use one of the following types:
		//		scale
		//		alpha
		//		transform_npcs
		//		glow_filter
			
		private const AddBalloon:String 	= "balloon";
		private const AddFollower:String 	= "follower";
		private const AddGum:String 		= "gum";
		private const AddPopFollower:String = "pop_follower";
		private const AddStars:String 		= "stars_circle";
		private const BobbleHead:String 	= "bobblehead";
		private const SetHandParts:String 	= "set_hands";
		
		// avatar effect with glow abilities
		private const AtomPower:String 		= "glow_filter";
		private const ElectroPower:String 	= "glow_filter";
		
		// weather abilities
		private const AddSnow:String 		= "weather";
		private const ColdWindPower:String 	= "weather";
		private const MeteorShower:String 	= "weather";
		private const RainAssets:String 	= "weather";
		
		// screen animation abilities
		private const GlitchPower:String 	= "screen_anim";
		private const PlayPopupAnim:String 	= "screen_anim";
		private const ScreenSwarm:String 	= "screen_anim";
		
		// flying/gliding abilities
		private const MagicCarpet:String 	= "flying";
		private const SlowFall:String 		= "flying";
		
		public function getType(className:String):String
		{
			return this[className];
		}
	}
}