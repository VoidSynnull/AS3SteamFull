package game.data.character
{
	import game.systems.entity.EyeSystem;
	import game.util.ArrayUtils;
	import game.util.DataUtils;
	import game.util.SkinUtils;

	/**
	 * Drew Martin
	 * 
	 * Use poptropica/asLib/avatar.as as a reference for what parts to use.
	 * 
	 * Things are beginning to need the default character looks. This could be all static, but not sure if it's the best idea
	 * to have this hanging around when it's not needed. Currently have to instantiate this to get values.
	 */
	public class PartDefaults
	{
		public function PartDefaults()
		{}
		
		public function getPlayerLook():LookData
		{
			var lookData:LookData = new LookData();
			return lookData;
		}
		
		public function randomLookData(lookData:LookData = null, gender:String = ""):LookData
		{
			if(!lookData) lookData = new LookData();
			
			if(!DataUtils.validString(gender)) gender = ArrayUtils.getRandomElement([SkinUtils.GENDER_MALE, SkinUtils.GENDER_FEMALE]);
			
			var skinColor:Number	= ArrayUtils.getRandomElement(this.skinColors);
			var hairColor:Number 	= ArrayUtils.getRandomElement(this.hairColors);
			var eyeState:String 	= ArrayUtils.getRandomElement([EyeSystem.OPEN, EyeSystem.SQUINT]);
			var marks:String;
			var mouth:String;
			var facial:String;
			var hair:String;
			var pants:String;
			var shirt:String;
			
			switch(gender)
			{
				case SkinUtils.GENDER_MALE:
					marks 	= ArrayUtils.getRandomElement(this.marksBoy);
					mouth 	= ArrayUtils.getRandomElement(this.mouthBoy);
					facial 	= ArrayUtils.getRandomElement(this.facialBoy);
					hair 	= ArrayUtils.getRandomElement(this.hairBoy);
					pants 	= ArrayUtils.getRandomElement(this.pantsBoy);
					shirt 	= ArrayUtils.getRandomElement(this.shirtBoy);
					break;
				
				case SkinUtils.GENDER_FEMALE:
					marks 	= ArrayUtils.getRandomElement(this.marksGirl);
					mouth 	= ArrayUtils.getRandomElement(this.mouthGirl);
					facial 	= ArrayUtils.getRandomElement(this.facialGirl);
					hair 	= ArrayUtils.getRandomElement(this.hairGirl);
					pants 	= ArrayUtils.getRandomElement(this.pantsGirl);
					shirt 	= ArrayUtils.getRandomElement(this.shirtGirl);
					break;
				
				default:
					throw new Error("PartDefaults :: randomLookData() :: A gender of " + gender + " is invalid");
					break;
			}
			
			lookData.applyLook(gender, skinColor, hairColor, eyeState, marks, mouth, facial, hair, pants, shirt);
			return lookData;
		}
		
		public const skinColors:Array 	= [0xFFCC99, 0xF5CD70, 0xD89210, 0x8E3D06, 0xFFDFD5];
		public const hairColors:Array 	= [0xFFCC99, 0xF5CD70, 0xD89210, 0x8E3D06, 0xFFFF00, 0xFFCC33, 0xFF3300, 0xCCCCCC, 0x522303, 0x351602];
		
		public const marksBoy:Array		= ["empty", "empty", "empty", "empty", "freckles", "freckles", "hairburns", "lc_boy", "wwphoto"];
		public const marksGirl:Array 	= ["empty", "empty", "empty", "astroprincess", "bangs1", "bangs2", "bangs3", "bangs4", "beautymark", "freckles", "ppirategirl1", "townie4", "wwSaloonGirl"];
		
		public const mouthBoy:Array 	= [1, 2, 5, 6, 14, 15, 16, 17, "fisherman", "teethgrin1", "fastfood", "montgomery", "astroguard1", "sponsorec2"];
		public const mouthGirl:Array 	= [1, 2, 5, 6, 9, 10, 11, 14, 15, 16, 17, 18, 19, "astroguard1", "astroroyal1", "astroservant1", "athena", "curator", "fastfood", "fisherman", "montgomery", "mythbeach1", "mythbeach2", "mythpes1", "mythteen1", "mythteen2", "pcowgirl1", "skullnavigator", "sponsorec2", "teethgrin1", "wwsaloongirl"];
		
		public const facialBoy:Array 	= ["empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", 2, "bl_drem", "mk_writer", "mk_disgruntled_programmer", "nateg", "realityteen", "ss"];
		public const facialGirl:Array 	= ["empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", 2, 4, "bl_drem", "bl_critic02", "curator", "librarian", "mk_cutter", "nateg", "realityteen", "sponsor_LM_Stella", "ss"];
		
		public const hairBoy:Array 	= [1, 6, 7, 9, 10, 22, 26, 34, 35, 36, 44, "gasDude", "gulliver", "lc_slayton", "mc_loverboy", "nateg", "realityteen", "referee", "SRishmael", "tourguide", "VCgothBoy", "wwprisoner"];
		public const hairGirl:Array	= [1, 23, 27, 29, 32, 39, 40, 43, "astroPrincess", "bl_barf", "curator", "girlhair4", "girlhair5", "girlhair6", "mikesmarket", "mtdancer", "mthtownie02", "mythbeach2", "sears1", "sears2", "sears3", "soccer", "sponsorAuntOpal", "sponsorfarmgirl", "SRishmael", "srmom", "srstubb", "srstarbuck", "VCgothGirl", "z_disco3"];
		
		public const pantsBoy:Array 	= [1, 2, 3, 6, 10, "adams", "astroalien1", "astroalien3", "astrofarmer", "astroking", "astrogossip3", "astroguard1", "astrozone", "conworker1", "eiffel", "finvendor", "mc_junior"];
		public const pantsGirl:Array 	= [1, 2, 3, 4, 8, 9, 10, 12, 14, "adams", "astroalien1", "astroalien2", "astroalien4", "astroguard1", "astrozone", "balloonpilate01", "bl_cashier", "buckyfan", "conworker1", "directord", "girlskirt1", "girlskirt2", "girlskirt3", "girlskirt4", "girlskirt5", "mc_junior", "sponsorMargo"];
		
		public const shirtBoy:Array 	= [1, 4, 5, 11, 13, 21, 22, 26, "balloonpilot02", "biker", "bl_cashier", "bl_dref", "bl_drem", "bluetie", "boyshirt1", "counterres1", "counterres2", "edworker1", "gtinfoil", "hashimoto", "hiker", "lc_boy", "mikesmarket", "mime", "nw_burg", "nim2", "patron1", "realityboy", "sears4", "tourist", "wwman"];
		public const shirtGirl:Array	= [2, 3, 4, 5, 7, 9, 10, 11, 12, 19, 23, 25, 26, "balloonpilot02", "biker", "bl_mom02", "bl_sofia", "counterres1", "gtinfoil", "hiker", "mime", "momchar1", "musicshirt1", "musicshirt2", "nw_gshirt02", "realitygirl", "sears1", "shirtvest1", "shirtvest2", "sponsorCityGirl", "srgirl", "tourist", "tt_boy", "wwcowgirl"];
		}
}