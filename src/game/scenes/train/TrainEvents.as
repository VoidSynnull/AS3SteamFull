package game.scenes.train
{
	import game.scenes.train.adGroundH16.*;
	import game.scenes.train.anthonyCabin.*;
	import game.scenes.train.bathroom.*;
	import game.scenes.train.clubExterior.*;
	import game.scenes.train.clubInterior.*;
	import game.scenes.train.coachCar.*;
	import game.scenes.train.coalCar.*;
	import game.scenes.train.diningCar.*;
	import game.scenes.train.edisonCabin.*;
	import game.scenes.train.extraCabin.*;
	import game.scenes.train.ferrisWheel.*;
	import game.scenes.train.freightCar.*;
	import game.scenes.train.houdiniCabin.*;
	import game.scenes.train.leMondeCabin.*;
	import game.scenes.train.luggageCar.*;
	import game.scenes.train.mainStreet.*;
	import game.scenes.train.midwayLeft.*;
	import game.scenes.train.midwayRight.*;
	import game.scenes.train.pinkertonCar.*;
	import game.scenes.train.portersCloset.*;
	import game.scenes.train.presidentialCar.*;
	import game.scenes.train.rooftops.*;
	import game.scenes.train.teslaCabin.*;
	import game.scenes.train.trainStop.*;
	import game.scenes.train.twainCabin.*;
	import game.scenes.train.vipCar1.*;
	import game.scenes.train.vipCar2.*;
	import game.scenes.train.wcStation.*;
	import game.data.island.IslandEvents;
	
	public class TrainEvents extends IslandEvents
	{
		public function TrainEvents()
		{
			super();
			super.scenes = [AdGroundH16,game.scenes.train.mainStreet.MainStreet,AnthonyCabin,Bathroom,ClubExterior,ClubInterior,CoachCar,CoalCar,DiningCar,EdisonCabin,ExtraCabin,FerrisWheel,FreightCar,HoudiniCabin,LeMondeCabin,LuggageCar,MidwayLeft,MidwayRight,PinkertonCar,PortersCloset,PresidentialCar,Rooftops,TeslaCabin,TrainStop,TwainCabin,VipCar1,VipCar2,WcStation];
		}

		// events
		public const ARRIVED_AT_FAIR:String				= "arrivedAtFair";
		public const BRIEFCASE_CHAT:String				= "briefcaseChat";
		public const CAUGHT_TESLA:String				= "caughtTesla";
		public const CHECKED_TESLA_CABIN:String			= "checkedTeslaCabin";
		public const ENTERED_TRAIN:String				= "enteredTrain";
		public const FINAL_CHASE_STARTED:String		 	= "finalChaseStarted";
		public const FOUND_MANUSCRIPT:String			= "foundManuscript";
		public const GET_PORTERS_OUTFIT:String			= "getPortersOutfit";
		public const GOT_PITCHER:String					= "gotPitcher";
		public const HOUDINI_CHASE_STARTED:String		= "houdiniChaseStarted";
		public const HOUDINI_FELL:String			 	= "houdiniFell";
		public const HOUDINI_SAVED:String				= "houdiniSaved";
		public const INVESTIGATED_COAL:String			= "investigatedCoal";
		public const INVESTIGATED_JUICE:String		 	= "investigatedJuice";
		public const MET_EVERYONE:String				= "metEveryone";
		public const MET_ANTHONY:String					= "metAnthony";
		public const MET_EIFFEL:String					= "metEiffel";
		public const MET_FERRIS:String					= "metFerris";
		public const MET_LE_MONDE:String				= "metLeMonde";
		public const MET_NY_TIMES:String				= "metNyTimes";
		public const MET_TESLA:String					= "metTesla";
		public const MET_TWAIN:String					= "metTwain";
		public const MET_WEISZ:String					= "metWeisz";
		public const MID_1_CHASE_STARTED:String			= "mid1ChaseStarted";
		public const MID_2_CHASE_STARTED:String			= "mid2ChaseStarted";
		public const POURED_PITCHER:String				= "pouredPitcher";
		public const PUSH_CRATE_CHAT:String 			= "pushCrateChat";
		public const PUSHED_CRATE:String				= "pushedCrate";
		public const RELEASED_TESLA:String				= "releasedTesla";
		public const STARTED_INVESTIGATION:String		= "startedInvestigation";
		public const TALKED_TO_CLEVELAND:String			= "talkedToCleveland";
		public const TESLA_FIND_DIFF:String				= "teslaFindDiff";
		public const TESLA_LEFT_BATHROOM:String			= "teslaLeftBathroom";
		public const TESLA_RELEASE_CHAT:String			= "teslaReleaseChat";
		public const TESLA_RETURN_BATHROOM:String		= "teslaReturnBathroom";
		public const TOTEMS_FELL:String				 	= "totemsFell";
		public const TRAIN_STOPPED:String				= "trainStopped";
		
		// clues		
		public const CLUE_DEVICE_STOLEN:String  		= "clueDeviceStolen";
		public const CLUE_TESLA_CABIN:String			= "clueTeslaCabin";
		public const CLUE_TWAIN:String					= "clueTwain";
		public const CLUE_PRUNE_JUICE:String			= "cluePruneJuice";
		public const CLUE_COAL_SMUDGES:String			= "clueCoalSmudges";
		public const CLUE_SNACK:String 					= "clueSnack";
		public const CLUE_TESLA_PRUNE:String			= "clueTelsaPrune";
		public const CLUE_GRAINY_PICTURE:String	 		= "clueGrainyPicture";
		public const CLUE_BRIEFCASE:String				= "clueBriefcase";
		public const CLUE_WEISZ:String 					= "clueWeisz";
		public const CLUE_TIMES_ARTICLE:String		 	= "clueTimesArticle";
		public const CLUE_TESLA:String					= "clueTesla";
		public const CLUE_TRANSFORMER:String 			= "clueTransformer";
		public const CLUE_SILHOUETTE:String				= "clueSilhouette";
		public const CLUE_TRUNK:String 					= "clueTrunk";
		public const CLUE_PINKERTONE_BLOCK:String 		= "cluePinkertonBlock";
		

		// temporary events (not saved on server)
		public const ASK_TO_DISEMBARK:String 			= "askToDisembark";
		
		public const RELEASED_TESLA_2:String			= "releasedTesla2";
		public const RELEASED_TESLA_3:String			= "releasedTesla3";
		public const RELEASED_TESLA_RESPONSE:String 	= "releasedTeslaResponse";
		public const RELEASED_TESLA_REPLY:String		= "releasedTeslaReply";
		
		public const ALREADY_HAVE_PAMPHLET:String		= "already_have_pamphlet";
		
		// items
		public const EDISON_LIGHT_BULB:String  			= "edisonLightBulb";
		public const EIFFEL_TOWER_HAT:String		 	= "eiffelTowerHat";
		public const GRAINY_PICTURE:String 				= "grainyPicture";
		public const LE_MONDE_PAPER:String				= "leMondePaper";
		public const LOCK_PICK_BAG:String 				= "lockPickBag";
		public const LUGGAGE_KEY:String 				= "luggageKey";
		public const MAGICIANS_HAT:String 				= "magiciansHat";
		public const MARK_TWAIN_HAIRCUT:String			= "markTwainHaircut";
		public const MEDALLION_TRAIN:String				= "medallionTrain";
		public const NEW_YORK_TIMES:String				= "newYorkTimes";
		public const PENCIL:String						= "pencil";
		public const PORTER_OUTFIT:String				= "porterOutfit";
		public const SCISSORS:String					= "scissors";
		public const SKETCH_OF_TESLAS_CABIN:String 		= "sketchOfTeslasCabin";
		public const TELEGRAM:String 					= "telegram";
		public const TESLA_COIL:String					= "teslaCoil";
		public const TRAIN_TICKET:String				= "trainTicket";
		public const TRANSFORMER:String					= "transformer";
		public const TRANSFORMER_SKETCH:String			= "transformerSketch";
		public const WOMENS_SUFFRAGE_PAMPHLET:String	= "womensSuffragePamphlet";
		public const PORTERS_NOTEPAD:String				= "portersNotepad";
	}
}