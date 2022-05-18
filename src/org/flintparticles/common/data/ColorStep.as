package org.flintparticles.common.data 
{
	/**
	 * Data class used to define a color with a <code>ColorMutliStep</code>.
	 * Has just two variables:
	 * color which defines the color
	 * energy which defines at what energy during the particle's life the color is fully apllied
	 * @author ... Bard McKinley
	 */
	public class ColorStep 
	{
		public var color:Number;
		public var energy:Number;
		
		public function ColorStep( color:Number, energy:Number  ) 
		{
			this.color = color;
			this.energy = energy;
		}
	}

}