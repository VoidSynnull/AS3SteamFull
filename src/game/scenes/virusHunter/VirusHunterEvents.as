package game.scenes.virusHunter
{
	import game.scenes.virusHunter.adStreet.AdStreet;
	import game.scenes.virusHunter.adStreetR.AdStreetR;
	import game.scenes.virusHunter.anteArm.AnteArm;
	import game.scenes.virusHunter.backRoom.BackRoom;
	import game.scenes.virusHunter.bloodStream.BloodStream;
	import game.scenes.virusHunter.brain.Brain;
	import game.scenes.virusHunter.cityLeft.BonusQuestPopup;
	import game.scenes.virusHunter.cityLeft.CityLeft;
	import game.scenes.virusHunter.cityRight.CityRight;
	import game.scenes.virusHunter.common.Common;
	import game.scenes.virusHunter.condoInterior.CondoInterior;
	import game.scenes.virusHunter.day2Heart.Day2Heart;
	import game.scenes.virusHunter.day2Intestine.Day2Intestine;
	import game.scenes.virusHunter.day2Lungs.Day2Lungs;
	import game.scenes.virusHunter.day2Mouth.Day2Mouth;
	import game.scenes.virusHunter.day2Stomach.Day2Stomach;
	import game.scenes.virusHunter.foreArm.ForeArm;
	import game.scenes.virusHunter.gym.Gym;
	import game.scenes.virusHunter.hand.Hand;
	import game.scenes.virusHunter.heart.Heart;
	import game.scenes.virusHunter.intestine.Intestine;
	import game.scenes.virusHunter.intestineBattle.IntestineBattle;
	import game.scenes.virusHunter.joesCondo.JoesCondo;
	import game.scenes.virusHunter.lungs.Lungs;
	import game.scenes.virusHunter.mainStreet.MainStreet;
	import game.scenes.virusHunter.mouth.Mouth;
	import game.scenes.virusHunter.mouthShip.MouthShip;
	import game.scenes.virusHunter.officeInterior.OfficeInterior;
	import game.scenes.virusHunter.pdcLab.DossierPopup;
	import game.scenes.virusHunter.pdcLab.PdcLab;
	import game.scenes.virusHunter.shipDemo.ShipDemo;
	import game.scenes.virusHunter.shipTutorial.ShipTutorial;
	import game.scenes.virusHunter.stomach.Stomach;
	import game.scenes.virusHunter.videoStore.VideoStore;
	import game.data.island.IslandEvents;
	
	public class VirusHunterEvents extends IslandEvents
	{
		public function VirusHunterEvents()
		{
			super();
			super.scenes = [AnteArm, Brain, Common, ForeArm, Gym, Hand, Heart, Intestine, IntestineBattle, Lungs, Mouth, MouthShip, Stomach, MainStreet, CityRight, CityLeft, CondoInterior, JoesCondo, OfficeInterior, ShipTutorial, VideoStore, BackRoom, PdcLab, BloodStream, Day2Stomach, Day2Intestine, Day2Heart, Day2Lungs, Day2Mouth, ShipDemo, DossierPopup, AdStreet, AdStreetR, BonusQuestPopup];
		}
		
		//events
		public const SAW_VAN_ON_MAIN:String 			= "saw_van_on_main";		// PDC van drove through main street
		public const SAW_VAN_ON_RIGHT:String 			= "saw_van_on_right";		// PDC van drove through cityRight, past video store
		public const USED_RESISTANCE_BAND:String		= "used_resistance_band";	// hung the band from the hook
		public const TALKED_TO_BERT:String 				= "talked_to_bert";			// Bert told you to go check out the van behind the condo
		public const VAN_LEFT:String 					= "van_left";				// PDC van left, dropping shredded documents
		public const GOT_SHREDS:String 					= "got_shreds";				// Got the shredded documents, can now show them to Bert
		public const ASSEMBLED_SHREDS:String 			= "assembled_shreds";		// Assembled the shredded documents, revealing identify of PDC
		public const DELIVERING_FALAFEL:String 			= "delivering_falafel";		// falafel man has left to deliver falafels to the office.
		public const DELIVERED_FALAFEL:String			= "delivered_falafel";		// falafel man ran through the office door.
		public const TOOK_JOES_PHOTO:String 			= "took_joe_photo";			// joe's photo has been taken at the office.
		public const BRAIN_BOSS_STARTED:String			= "brain_boss_started";
		public const BRAIN_BOSS_DEFEATED:String 		= "brain_boss_defeated";
		public const COMPLETED_TUTORIAL:String 			= "completed_tutorial";		// player has completed ship tutorial.
		public const ENTERED_JOE:String 				= "entered_joe";			// player has entered joe through chinese food.
		public const SEARCHED_MAIL:String 				= "searched_mail";			// searched the mail in condoInterior.
		public const HEART_BOSS_STARTED:String 			= "heart_boss_started";
		public const HEART_BOSS_DEFEATED:String 		= "heart_boss_defeated";
		public const FIXED_ARRHYTHMIA:String			= "fixed_arrhythmia";
		public const PASSED_HEART:String				= "passed_heart";			// player has gone through the heart by shocking the muscles open.
		public const START_WORKOUT_POPUP:String			= "start_workout_popup";
		public const USED_BADGE:String					= "used_badge"; 			//used badge to enter secret lab through video store
		public const LANGE_IN_BACK_ROOM:String			= "lange_in_back_room";
				
		//Mouth
		public const TOOTH_CHIPPED_:String 				= "tooth_chipped_";				// 4 stages of destruction before destroyed
		public const TOOTH_REMOVED:String	 			= "tooth_removed";
		public const HATCH_OPEN:String					= "hatch_open";
		public const HATCH_CLOSE:String					= "hatch_close";
		
		//Hand
		public const ATTACKED_BY_WBC:String				= "attacked_by_white_blood_cells";
		public const FIGHTING_INFECTION:String			= "fighting_infection";
		public const SPLINTER_REMOVED:String			= "splinter_removed";
		public const CLOGGED_HAND_CUT_:String 			= "clogged_hand_cut_"; 			// 4 cuts in the hand
		public const HAND_HEMORRHAGES_CURED:String 		= "hand_hemorrhages_cured";
		public const PART_STOLEN_:String			 	= "part_stolen_";				// 2 sounds
		
		//Upperarm
		public const CLOGGED_UPPER_ARM_CUT_:String		= "clogged_upper_arm_cut_"		// 5 cuts in upper arm
			
		//Forearm
		public const CLOGGED_FOREARM_CUT_:String 		= "clogged_forearm_cut_" 	// 3 cuts out of 7
		public const ARM_BOSS_DEFEATED:String 			= "arm_boss_defeated";
		public const DESTROYED_CALCIFICATION_:String 	= "destroyed_calcification_"; 	// 6 calcium deposits
		public const CALCIFCATION_REMOVED:String		= "calcification_removed"; 		// destroyed all 6 calcium deposits
		
		//Lungs
		public const BUS_CUTSCENE_PLAYED:String			= "bus_cutscene_played";
		public const LUNG_BOSS_DEFEATED:String			= "lung_boss_defeated";
		
		//Intestine
		public const BLOCKAGE_CLEARED_:String			= "blockage_cleared_"; 		//8 blockages
		public const BLOCKAGE_SHOT_:String				= "blockage_shot_";			//4 sounds, trigger event
		public const CRAMP_CURED:String					= "cramp_cured";
		
		//Intestine Battle
		public const INTESTINE_BOSS_DEFEATED:String		= "intestine_boss_defeated";
		
		//Stomach
		public const DRINK_CUTSCENE_PLAYED:String		= "drink_cutscene_played";
		public const SPLINTER_CUTSCENE_PLAYED:String	= "splinter_cutscene_played";
		public const ULCER_CURED:String					= "ulcer_cured";
		
		//Day 2
		public const ENTERED_DOG:String					= "entered_dog";
		public const EXITED_DOG:String					= "exited_dog";
		public const RETRACT_WORMS:String				= "retract_worms";
		public const WORM_CLEARED_:String				= "worm_cleared_";			//10 worms
		public const WORM_RETRACTED_:String				= "worm_retracted_";		//10 worms
		
		public const TALKED_TO_GIRL:String				= "talked_to_girl";
		public const TALKED_TO_LANGE_D2:String  		= "talked_to_lange_d2";     //After talking to lange about dog
		public const DOG_IN_CITY_LEFT:String			= "dog_in_city_left"; 		//Group Event
		public const DOG_IN_MAIN_STREET:String			= "dog_in_main_street";		//Group Event
		public const GIRL_IN_CITY_LEFT:String			= "girl_in_city_left"; 		//Group Event
		public const GIRL_IN_MAIN_STREET:String			= "girl_in_main_street";	//Group Event
		public const STARTED_BONUS_QUEST:String			= "started_bonus_quest";
		public const BLOCKED_FROM_BONUS:String			= "blocked_from_bonus";
		
		//Day 2 Stomach
		public const DOG_TREAT_CLEARED_:String			= "dog_treat_cleared_"; 	//6 treats
		public const STOMACH_FAT_CLEARED_:String		= "stomach_fat_cleared_";	//8 fat areas
		
		//Day 2 Mouth
		public const DOG_CUT_CURED_:String				= "dog_cut_cured_";			//5 cuts
		
		//Day 2 Lungs
		public const LUNG_WORMS_DEFEATED:String			= "lung_worms_defeated";
		
		//Day 2 Heart
		public const WORM_BOSS_DEFEATED:String 			= "worm_boss_defeated";
		
		public const GOT_:String 						= "got_";
		public const GOT_GOO:String 					= "got_goo";
		public const GOT_SHOCK:String					= "got_shock";
		public const GOT_SCALPEL:String 				= "got_scalpel";
		public const GOT_SHIELD:String 					= "got_shield";
		public const GOT_ANTIGRAV:String 				= "got_antiGrav";
		
		//Triggered Events
		public const BOSS_BATTLE_STARTED:String			= "boss_battle_started";	//Triggers start of boss battle music for scenes
		public const BOSS_BATTLE_ENDED:String			= "boss_battle_ended";
		public const SPAWN_EVOVIRUS:String				= "spawn_evovirus";
		
		public const MUSCLE_CONTRACT:String				= "muscle_contract";
		public const MUSCLE_EXPAND:String				= "muscle_expand";
		public const SHOW_BADGE:String				    = "showBadge";
		
		//items
		public const RESISTANCE_BAND:String 	= "resistanceBand";
		public const SHIELD:String				= "shield";
		public const MEDAL_VIRUS:String			= "medalVirusHunter";
		public const PETRI_DISH:String			= "petriDish";
		public const FALAFEL:String				= "falafel";
		public const PDC_BADGE:String			= "pdcIdBadge";
		
		// USERFIELDS
		public const DAMAGE_FIELD:String		= "damage";
		public const WEAPON_FIELD:String		= "activeWeapon";
		public const GUN_LEVEL_FIELD:String		= "gunLevel";
		
	}
}