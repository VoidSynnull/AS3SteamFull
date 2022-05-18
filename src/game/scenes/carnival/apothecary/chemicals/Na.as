package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class Na extends Chemical implements IChem
	{
		public function Na($molecules:Molecules)
		{
			super(ChemicalGraphics.NA_GRAPHIC, $molecules);
		}
	}
}