package game.scenes.carnival.tunnelLove.components
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class Boat extends Component
	{
		
		public function Boat($boatEntity:Entity, $platformEntity:Entity, $rippleEntity:Entity):void{
			boatEntity = $boatEntity;
			platformEntity = $platformEntity;
			ripples = $rippleEntity;
			platformOffset = new Point(Spatial(boatEntity.get(Spatial)).x - Spatial(platformEntity.get(Spatial)).x, Spatial(boatEntity.get(Spatial)).y - Spatial(platformEntity.get(Spatial)).y);
		}
		
		public var boatEntity:Entity; // boat entity in the scene
		public var ripples:Entity;
		public var platformEntity:Entity; // platform player stands on in the boat
		public var platformOffset:Point; // the offset of the x and y coords of the platform vs the boat x and y coords
		public var xVelocity:Number = 1; // movement of boat and platform
	}
}