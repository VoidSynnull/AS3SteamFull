package game.scenes.lands.shared.monsters {

	/**
	 * this class might also be called MonsterLook; it stores the indices
	 * into the monster look arrays which give the monster its features.
	 * 
	 * these values could all be squashed into the LandMonster component - which isn't doing
	 * much right now. but uh.. maybe.. this is more organized? who knows.
	 */
	public class MonsterData {

		public var variantIndex:int;

		public var facialIndex:int;
		public var eyeIndex:int;
		public var mouthIndex:int;
		public var hairIndex:int;
		public var marksIndex:int;

		public var shirtIndex:int;
		public var pantsIndex:int;
		public var overshirtIndex:int;
		public var overpantsIndex:int;

		public var packIndex:int;
		public var itemIndex:int;

		public var skinColorIndex:int;
		public var hairColorIndex:int;

		/**
		 * before it's saved, the scale needs to be converted to an integer between 1 and 64
		 */
		public var scale:Number;

		public function MonsterData() {
		}

	} // class
	
} // package