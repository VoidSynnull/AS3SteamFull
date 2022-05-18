package game.scenes.lands.shared.classes {

	public class LandEditMode {

		static public const PLAY:uint = 1;
		static public const MINING:uint = 2;
		static public const EDIT:uint = 4;

		/**
		 * used for ad campaigns that need custom land modes.
		 * this mode can be OR'd with other modes, in order to combine mode types.
		 */
		static public const SPECIAL:uint = 32;

		/**
		 * user is creating or placing a template.
		 * this might not be used as a standard edit mode, since the previous edit mode
		 * would need to be saved. maybe an OR? or maybe just save the previous mode
		 * in the template system.
		 */
		static public const TEMPLATE:uint = 8;

		/**
		 * this is actually a subtype of EDIT mode. ideally there would be a separate class
		 * for specifying subtypes like TEMPLATE and DECAL. They would be "CreateMode" types.
		 */
		static public const DECAL:uint = 16;

	} //

} // package.
