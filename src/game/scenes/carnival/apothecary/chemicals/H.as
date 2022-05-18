package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class H extends Chemical implements IChem
	{
		public function H($molecules:Molecules)
		{
			super(ChemicalGraphics.H_GRAPHIC, $molecules);
		}
	}
}