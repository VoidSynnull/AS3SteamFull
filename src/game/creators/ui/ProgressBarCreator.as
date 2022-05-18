package game.creators.ui
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.motion.FollowTarget;
	import game.components.ui.ProgressBar;
	import game.systems.SystemPriorities;
	import game.systems.ui.ProgressBarSystem;
	import game.util.EntityUtils;

	public class ProgressBarCreator
	{
		public function ProgressBarCreator()
		{
		}
		
		public function createFromDisplay(displayObject:DisplayObjectContainer, group:Group = null):Entity
		{
			var entity:Entity = new Entity();
			var progressBar:ProgressBar = new ProgressBar();
			progressBar.percent = 0;
			progressBar.hideWhenInactive = false;
			var display:Display = new Display(displayObject);
			
			entity.add(progressBar);
			entity.add(display);
			
			if(group != null)
			{
				group.addEntity(entity);
				
				if(!group.hasSystem(ProgressBarSystem))
				{
					group.addSystem(new ProgressBarSystem(), SystemPriorities.lowest);
				}
			}
			
			return(entity);
		}
		
		public function create(group:Group, container:DisplayObjectContainer, parent:Entity = null, asset:String = "ui/general/progressBar.swf", offset:Point = null):Entity
		{
			var entity:Entity = new Entity();
			var progressBar:ProgressBar = new ProgressBar();
			progressBar.percent = 0;
			
			entity.add(progressBar);
			entity.add(new Spatial());
			
			if(parent)
			{
				EntityUtils.addParentChild(entity, parent);
				var followTarget:FollowTarget = new FollowTarget(parent.get(Spatial), .3, false);
				followTarget.offset = offset;
				entity.add(followTarget);
			}
			
			group.addEntity(entity);
			
			if(!group.hasSystem(ProgressBarSystem))
			{
				group.addSystem(new ProgressBarSystem(), SystemPriorities.lowest);
			}
			
			group.shellApi.loadFile(group.shellApi.assetPrefix + asset, loaded, container, entity);
			
			return(entity);
		}
		
		private function loaded(clip:MovieClip, container:DisplayObjectContainer, entity:Entity):void
		{
			var display:Display = new Display(clip);
			var progressBar:ProgressBar = entity.get(ProgressBar);
			if(progressBar.hideWhenInactive) { clip.alpha = display.alpha = 0; }
			container.addChild(clip);
			entity.add(display);
		}
	}
}