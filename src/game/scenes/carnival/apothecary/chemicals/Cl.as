package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class Cl extends Chemical implements IChem
	{
		public function Cl($molecules:Molecules)
		{
			super(ChemicalGraphics.CL_GRAPHIC, $molecules);
		}
	}
}