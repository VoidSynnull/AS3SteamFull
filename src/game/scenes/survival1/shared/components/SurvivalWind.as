package game.scenes.survival1.shared.components
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import game.scenes.survival1.shared.Wind;
	import game.scenes.survival1.shared.systems.SurvivalWindSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.PerformanceUtils;
	
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class SurvivalWind extends Component
	{
		public var wind:Emitter2D; // the emitter
		public var viewPort:Rectangle;// the bounds of what can be seen so the emitter can emit around it
		public var maxStrongWind:Number;// the max velocity of a strong wind
		public var minStrongWind:Number;// the min velocity of a strong wind
		public var fallSpeed:Number;//how fast the snow falls
		public var windVelocity:Number = 0;// the velocity for the wind
		public var changeTime:Number = 0;// where in the cycle the wind is
		public var windChangeTime:Number;//how long it takes to cycle through wind changes
		public var windSwingPower:Number = 5;// how drastically wind chages from blowing one direction to going static to blowing the other
		public var maxParticles:int = 15;
		
		public var strongWind:Signal;
		public var weakWind:Signal;
		
		public var strongWinds:Boolean;
		public var blowingRight:Boolean;
		public var ignoreMe:Boolean;
		
		public function SurvivalWind(viewPort:Rectangle, windSwingPower:Number = 5, directionalTime:Number = 30, maxStrongWind:Number = 500, minStrongWind:Number = 125, fallSpeed:Number = 100, buffer:Number = 0, ignoreLevel:int = 0)
		{
			ignoreMe = PerformanceUtils.qualityLevel < ignoreLevel;
			
			if(!ignoreMe)
			{
				center = new Point(viewPort.width / 2, viewPort.height / 2);
				
				emitterRadius = Math.sqrt(Math.pow(center.x, 2) + Math.pow(center.y, 2)) + buffer;
				emitterWidth = Math.sqrt(Math.pow(viewPort.width, 2) + Math.pow(viewPort.height, 2)) + buffer; 
				deathRadius = Math.sqrt(Math.pow(emitterRadius, 2) + Math.pow(emitterWidth, 2)) + buffer; 
				
				wind = new Emitter2D();
				
				counter = new Random(5,5);
				
				wind.counter = counter;
				
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot(2));
				
				// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
				wind.addInitializer( new BitmapImage(bitmapData) );
				
				//wind.addInitializer(new ImageClass(Dot,[2],true));
				wind.addInitializer(new ScaleImageInit(.5, 1.5));
				
				windZone = new PointZone(new Point());
				wind.addInitializer(new Velocity(windZone));
				
				startSide = new LineZone(new Point(), new Point());
				wind.addInitializer(new Position(startSide));
				
				wind.addAction(new Move());
				//wind.addAction( new DeathZone(new EllipseZone(center,deathRadius, deathRadius),true));
				wind.addAction(new DeathZone(new RectangleZone(-emitterWidth, -emitterRadius, emitterWidth, emitterRadius),true));
				wind.addAction(new RandomDrift(maxStrongWind / 2, fallSpeed));
				
				windAction = new Wind();
				wind.addAction(windAction);
			}
			
			this.viewPort = viewPort;
			this.maxStrongWind = maxStrongWind;
			this.minStrongWind = minStrongWind;
			this.fallSpeed = fallSpeed;
			this.windChangeTime = directionalTime;
			this.windSwingPower = windSwingPower;
			
			this.strongWinds = false;
			this.blowingRight = true;
			this.strongWind = new Signal(Boolean);
			this.weakWind = new Signal(Boolean);
		}
		
		private var startSide:LineZone;// a line perpendicular to the direction of the wind and opposite the direction so to create the effect of where the wind is coming from
		private var windZone:PointZone;// the zone of the initial velocity of the wind
		private var windAction:Wind;// the action for making the wind change directions on the fly
		private var counter:Random;// making it so that when the wind is weak less snow is produced, and when the wind is strong more snow is produced so it doesnt seem so sparse as when it was constant
		
		private var emitterRadius:Number;// making sure the emitter will never emit from off screen
		private var emitterWidth:Number;// the widest range it needs to be able to cover the screen
		private var deathRadius:Number;// the radius of what is safe before a particle gets destroyed
		private var center:Point;// the center of the view port
		
		public function changeWindDirection(direction:Number):void
		{
			windVelocity = maxStrongWind * direction;
			
			if(!ignoreMe)
			{
			
				windZone.point = new Point(windVelocity,fallSpeed);
				
				windAction.setVelocityX(windVelocity);
				
				var windDirection:Number = Math.atan2(fallSpeed, -windVelocity);
				
				counter.maxRate = int(Math.max(counter.minRate + 1, Math.abs(windVelocity / 10 / SurvivalWindSystem.updateRatio)));
				
				counter.maxRate = Math.min(counter.maxRate, maxParticles);
				
				startSide.startX = center.x - Math.sin(windDirection) * emitterWidth / 2 + Math.cos(windDirection) * emitterRadius;
				startSide.startY = center.y - Math.sin(windDirection) * emitterRadius - Math.cos(windDirection) * emitterWidth / 2;
				
				startSide.endX = center.x + Math.sin(windDirection) * emitterWidth / 2 + Math.cos(windDirection) * emitterRadius;
				startSide.endY = center.y - Math.sin(windDirection) * emitterRadius + Math.cos(windDirection) * emitterWidth / 2;
				
				// creates a tangental line from the angle of the wind, the center of the screen, 
				//and with a radius of emitterRadius (which is the distance to the corner of the screen + whatever buffer was given)
				
			}
			var strong:Boolean = Math.abs(windVelocity) > minStrongWind;
			var right:Boolean = direction >= 0;
			
			if(strong && !strongWinds)
				strongWind.dispatch(right);
			if(!strong && strongWinds)
				weakWind.dispatch(right);
			if(blowingRight != right)
				weakWind.dispatch(right);
			
			strongWinds = strong;
			blowingRight = right;
			
			// dispatches for change of direction and when wind really picks up or really dies down
		}
		
		public function getWindVelocity():Point
		{
			return new Point(windVelocity, fallSpeed);
		}
	}
}