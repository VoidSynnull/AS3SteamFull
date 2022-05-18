package game.scenes.carnival.apothecary.chemicals.data
{
	import game.scenes.carnival.apothecary.chemicals.Br;
	import game.scenes.carnival.apothecary.chemicals.Cl;
	import game.scenes.carnival.apothecary.chemicals.Fr;
	import game.scenes.carnival.apothecary.chemicals.Gl;
	import game.scenes.carnival.apothecary.chemicals.H;
	import game.scenes.carnival.apothecary.chemicals.Na;
	import game.scenes.carnival.apothecary.chemicals.OH;
	import game.scenes.carnival.apothecary.chemicals.P1;
	import game.scenes.carnival.apothecary.chemicals.P2;
	import game.scenes.carnival.apothecary.chemicals.P3;
	import game.scenes.carnival.apothecary.chemicals.X1;
	import game.scenes.carnival.apothecary.chemicals.X2;
	import game.scenes.carnival.apothecary.chemicals.X3;

	public class Compounds
	{
		/**
		 * First element in array is the compound.
		 * Second element in array is the reactant data in respective to the subindex(s) of the first element
		 * @reactsWith - which chemical it reacts with
		 * @offSet - graphic correction of element upon reaction
		 */

		// SALT REAGENTS -----------------------------------------------------------------------------------
		public static const SODIUM_HYDROXIDE:Array = [[Na,OH], 	// chemical composition [chem1,chem2]
				[{reactsWith:Cl},		// chem1 reaction
				 {reactsWith:H}]];		// chem2 reaction
		
		public static const HYDROCHLORIC_ACID:Array = [[H,Cl],	// chemical composition [chem1,chem2]
				[{reactsWith:OH},		// chem1 reaction
				 {reactsWith:Na}]];		// chem2 reaction
		
		// SUGAR REAGENTS ----------------------------------------------------------------------------------
		public static const FRUCTOSE:Array = [[Fr,OH],			// chemical composition [chem1,chem2]
				[{reactsWith:Gl},		// chem1 reaction
				 {reactsWith:H}]];		// chem2 reaction
		
		public static const GLUCOSE:Array = [[H,Gl],			// chemical composition [chem1,chem2]
				[{reactsWith:OH},		// chem1 reaction
				 {reactsWith:Fr}]];		// chem2 reaction
		
		// SODIUM THIOPENTAL REAGENTS ----------------------------------------------------------------------
		public static const BROMOPENTANE:Array = [[P1,Br],		// chemical composition [chem1,chem2]
				[{reactsWith:P2}, 		// chem1 reaction
				 {reactsWith:H}]]; 		// chem2 reaction
		
		public static const ETHLYMALONIC_ESTER:Array = [[H,P2,OH],  // chemical composition [chem1,chem2,chem3]
				[{reactsWith:Br},											// chem1 reaction
				[{reactsWith:P3},{reactsWith:P1}],  // chem2 reaction ( reacts with 2 different chemicals)
				 {reactsWith:Na}]];											// chem3 reaction
		
		public static const SODIUM_SULFIDESODIUM:Array = [[Na,P3],  // chemical composition [chem1,chem2]
				[{reactsWith:OH},			// chem1 reaction
				 {reactsWith:P2}]];			// chem2 reaction
		
		// CHEMICAL X REAGENTS -----------------------------------------------------------------------------
		
		public static const MUSHROOM:Array = [[Na,X3], // chemical composition [chem1,chem2]
				[{reactsWith:Cl},	// chem1 reaction
				 {reactsWith:X2}]];	// chem2 reaction
		
		public static const PICKLE_JUICE:Array = [[X1,OH], // chemical composition [chem1,chem2]
			[{reactsWith:X2}, // chem1 reaction
			 {reactsWith:H}]]; // chem2 reaction
		
		public static const COLA:Array = [[H,X2,Cl],  // chemical composition [chem1,chem2,chem3]
				[{reactsWith:OH},						// chem1 reaction
				[{reactsWith:X1},{reactsWith:X3}],  	// chem2 reaction ( reacts with 2 different chemicals)
				{reactsWith:Na}]];
	}
}