package game.components.hit
{
	import ash.core.Component;
	
	public class Water extends Component
	{
		public var splashColor1:uint;   			// The beginning of a color range for splashes (32-bit hex value)
		public var splashColor2:uint;   			// The end of a color range for splashes (32-bit hex value)
		public var density:Number = 1;				// density of water per 100 pixels squared ( colliders with densities greater than water's will sink, lesser will float ) 
		public var viscosity:Number = .95;			// dampener on movement
		public var sceneWide:Boolean = false;		// if hit should encompass entire scene
	}
}
