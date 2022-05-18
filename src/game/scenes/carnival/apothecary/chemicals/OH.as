package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class OH extends Chemical implements IChem
	{
		public function OH($molecules:Molecules)
		{
			super(ChemicalGraphics.OH_GRAPHIC, $molecules);
		}
	}
}