package game.scenes.virusHunter.shared.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.EntityType;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.Pickup;
	import game.scenes.virusHunter.shared.data.PickupType;
	import game.util.TimelineUtils;
	import game.util.Utils;

	public class PickupCreator
	{
		public function PickupCreator(group:Group, container:DisplayObjectContainer)
		{
			_group = group;
			_container = container;
		}
		
		public function create(x:Number, y:Number, type:String, arcade:Boolean = true):void
		{
			var entity:Entity = new Entity();
			var motion:Motion = new Motion();
			var path:String = "scenes/virusHunter/shipDemo/";
			
			if(!arcade)
			{
				path = "scenes/virusHunter/shared/";
			}
			
			motion.rotationVelocity = Utils.randInRange(-200, 200);
			motion.velocity = new Point(Utils.randInRange(-100, 100), Utils.randInRange(-100, 100));
			
			entity.add(new EntityType(type));
			entity.add(new Spatial(x, y));
			entity.add(new Pickup());
			entity.add(motion);
			entity.add(new Sleep());
			entity.add(new MovieClipHit(PickupType.PICKUP, "ship"));
			
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + path + type + ".swf", assetLoaded, entity, _container);
			
			_group.addEntity(entity);
		}
		
		private function assetLoaded(clip:MovieClip, entity:Entity, container:DisplayObjectContainer):void
		{
			container.addChild(clip);
			entity.add(new Display(clip));
			
			TimelineUtils.convertClip(clip, _group, entity);
		}
		
		private var _group:Group;
		private var _container:DisplayObjectContainer;
	}
}