package game.scenes.virusHunter.shared.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.ui.ProgressBar;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.util.EntityUtils;

	public class LifeBarCreator
	{
		public function LifeBarCreator(group:Group, container:DisplayObjectContainer)
		{
			_group = group;
			_container = container;
		}
		
		public function create(parent:Entity, asset:String, offset:Point = null):void
		{
			var entity:Entity = new Entity();
			var parentSpatial:Spatial = parent.get(Spatial);
			var parentDamageTarget:DamageTarget = parent.get(DamageTarget);
			var followTarget:FollowTarget = new FollowTarget(parent.get(Spatial), .3, false);
			followTarget.offset = offset;
			
			var progressBar:ProgressBar = new ProgressBar();
			progressBar.range = parentDamageTarget.maxDamage;
			progressBar.sourceComponent = parentDamageTarget;
			progressBar.sourceProperty = "damage";
			
			entity.add(progressBar);
			entity.add(new Spatial(parentSpatial.x, parentSpatial.y));
			entity.add(followTarget);
			
			EntityUtils.addParentChild(entity, parent);
			
			_group.addEntity(entity);
			
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + asset, lifeBarLoaded, entity, _container);
		}
		
		private function lifeBarLoaded(clip:MovieClip, entity:Entity, container:DisplayObjectContainer):void
		{
			var display:Display = new Display(clip);
			clip.alpha = display.alpha = 0;
			container.addChild(clip);
			entity.add(display);
		}
		
		private var _group:Group;
		private var _container:DisplayObjectContainer;
	}
}