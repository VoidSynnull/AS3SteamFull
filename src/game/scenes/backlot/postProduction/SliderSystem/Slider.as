package game.scenes.backlot.postProduction.SliderSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class Slider extends Component
	{
		//types of sliders
		public const VERTICAL:String = "vertical";
		public const HORIZONTAL:String = "horizontal";
		public const RADIAL:String = "radial";
		//types of origins
		public const MIN_POINT:String = "min_point";
		public const MAX_POINT:String = "max_point";
		public const CENTER:String = "center";
		
		public var sliderType:String;
		public var origin:Point;// where you want it to default to
		public var offset:Point;//for taking care of parenting offsets
		public var scale:Point;//found an issue where parenting scale affected position
		public var originType:String;// if true, this will be considered
		public var maxDistance:Number;//used for determining the value (distance/maxdistance)
		// if using radial, max distance should be the radius of the circle you want
		
		public var dragger:Spatial;
		
		public var drag:Boolean;
			
		public var value:Point;//
		
		public var rotation:Number = 0;
		
		public var enabled:Boolean;
		
		public function Slider(dragger:Spatial = null, maxDistance:Number = 100, sliderType:String = "horizontal", originType:String = "center", origin:Point= null, offset:Point = null, scale:Point = null)
		{
			this.dragger = dragger;
			
			this.maxDistance = maxDistance;
			
			this.sliderType= sliderType;
			this.originType = originType;
			
			this.origin = origin;
			if(this.origin == null)
				this.origin = new Point();
			
			this.offset = offset;
			if(this.offset == null)
				this.offset = new Point();
			
			this.scale = scale;
			if(this.scale == null)
				this.scale = new Point(1,1);
			
			value = new Point();
			
			enabled = true;
		}
	}
}