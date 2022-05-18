package game.scenes.shrink.silvaOfficeShrunk01.SilvaSystem
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.Emitter;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;
	
	public class Silva extends Component
	{
		public var targetPoint:Point;
		public var waitPoint:Point;
		
		public var aimTime:Number;
		public var waitTime:Number;
		public var shootTime:Number;
		public var time:Number;
		
		public var laserSpatial:Spatial;
		public var laser:MovieClip;
		public var laserThickness:Number;
		public var laserColor:uint = 0x00e69a;
		
		public var shoot:Signal;
		public var backFire:Boolean;
		
		public static var WAIT:String = "wait";
		public static var AIM:String = "aim";
		public static var FIRE:String = "fire";
		
		public var silva:Spatial;
		public var charge:Emitter;
		public var glow:Display;
		
		public var state:String;
		
		public function Silva(silva:Spatial, charge:Emitter, group:Group, gun:MovieClip, targetPoint:Point, waitPoint:Point, laserThickness:Number = 10, shootTime:Number = .25, aimTime:Number = 2, waitTime:Number = 5)
		{
			this.silva = silva;
			this.charge = charge;
			charge.emitter.counter.stop();
			
			this.shootTime = shootTime;
			this.aimTime = aimTime;
			this.waitTime = waitTime;
			
			this.targetPoint = targetPoint;
			this.waitPoint = waitPoint;
			
			state = WAIT;
			
			time = waitTime / 2;
			shoot = new Signal(Point);
			
			laser = new MovieClip;
			var entity:Entity = EntityUtils.createSpatialEntity(group, laser, gun);
			entity.add(new Id("laser"));
			laserSpatial = entity.get(Spatial);
			entity = EntityUtils.createSpatialEntity(group, gun.powerGlow,gun);
			glow = entity.get(Display);
			DisplayUtils.moveToBack(laser);
			this.laserThickness = laserThickness;
			backFire = false;
		}
		
		public function setState(state:String):void
		{
			this.state = state;
			time = 0;
		}
	}
}