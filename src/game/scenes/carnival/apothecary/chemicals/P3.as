package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class P3 extends Chemical implements IChem
	{
		public function P3($molecules:Molecules)
		{
			super(ChemicalGraphics.P3_GRAPHIC, $molecules);
		}
	}
}