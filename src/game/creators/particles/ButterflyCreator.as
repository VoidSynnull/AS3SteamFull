package game.creators.particles
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.group.Group;
	
	import game.components.entity.OriginPoint;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.systems.motion.WaveMotionSystem;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	import game.components.scene.Butterfly;

	public class ButterflyCreator
	{
		public static function loadAndCreate(group:Group, container:DisplayObjectContainer, x:Number, y:Number, path:String = "particles/butterfly.swf"):void
		{
			group.shellApi.loadFile(group.shellApi.assetPrefix + path, create, group, container, x, y);
		}
		
		public static function create(clip:MovieClip, group:Group, container:DisplayObjectContainer = null, x:Number = NaN, y:Number = NaN):Entity
		{
			if(!isNaN(x)) clip.x = x;
			if(!isNaN(y)) clip.y = y;
			
			if(!group.getSystem(WaveMotionSystem))
			{
				group.addSystem(new WaveMotionSystem());
			}
			
			var entity:Entity = EntityUtils.createSpatialEntity(group, clip, container);
			TimelineUtils.convertAllClips(clip, null, group, true, 60, entity);
			
			entity.add(new OriginPoint(clip.x, clip.y));
			entity.add(new SpatialAddition());
			entity.add(new Tween());
			
			var wave:WaveMotion = new WaveMotion();
			wave.add(new WaveMotionData("y", 15, 1, "sin", 0, true));
			entity.add(wave);
			
			var butterfly:Butterfly = new Butterfly();
			entity.add(butterfly);
			
			butterfly.move(entity);
			return entity;
		}
	}
}