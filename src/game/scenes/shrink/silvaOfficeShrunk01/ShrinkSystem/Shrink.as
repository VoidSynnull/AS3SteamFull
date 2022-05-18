package game.scenes.shrink.silvaOfficeShrunk01.ShrinkSystem
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Shrink extends Component
	{
		public var hit:DisplayObject;
		public var scale:Number;
		public var shrink:Boolean;
		public var shrinking:Boolean;
		public var isShrunk:Boolean;
		public var shrinkable:Boolean;
		public var shrinkTime:Number;
		public var shrinkGlow:GlowFilter;
		public var glowIntensity:Number;
		
		public function Shrink( hit:DisplayObject, scale:Number = .25, glowIntensity:Number = 2, shrinkTime:Number = .5 )
		{
			this.hit = hit;
			this.glowIntensity = glowIntensity;
			shrinkGlow = new GlowFilter(0x00e69a,100,20,20,glowIntensity);
			
			shrink = false;
			shrinking = false;
			isShrunk = false;
			
			this.scale = scale;
			this.shrinkTime = shrinkTime;
			shrinkable = true;
		}
		
		public function isTarget( point:Point, container:DisplayObjectContainer = null ):Boolean
		{
			if( container != null )
				point = container.localToGlobal( point );
			
			return hit.hitTestPoint( point.x, point.y, true );
		}
		
		public function shrunk():void
		{
			this.isShrunk = true;
		}
	}
}