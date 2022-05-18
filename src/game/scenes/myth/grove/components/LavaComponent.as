package game.scenes.myth.grove.components
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	
	public class LavaComponent extends Component
	{
		public function LavaComponent( clip:MovieClip, spatial:Spatial )
		{
			pilar = clip;
			pilar.height = minScale;
			platformSpatial = spatial;
		}
		
		public var position:Position;
		public var emitter:Emitter2D;
		public var pilar:MovieClip;
		public var minScale:int = 100;
		
		public var platformSpatial:Spatial;
	}
}