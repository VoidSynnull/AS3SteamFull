package game.creators.video
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.video.PopVideo;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.ui.ToolTipType;
	import game.util.TimelineUtils;
	
	public class PopVideoCreator
	{
		/**
		 * Constructor
		 */
		public function PopVideoCreator():void
		{
		}
		
		/**
		 * Create AdVideo entity
		 * @param	group			Scene where the video is loaded
		 * @param	container		video container movieclip
		 * @param	videoData		object with all video data
		 */
		public function create(group:Group, container:MovieClip, videoData:Object):Entity
		{
			//create entity for container
			var popVideo:PopVideo = new PopVideo(null, container, videoData, group);
			var containerEntity:Entity = new Entity().add(popVideo);
			var display:Display = new Display(container);
			display.isStatic = true;
			containerEntity.add(new Spatial(container.x, container.y));
			containerEntity.add(display);
			containerEntity.add(new Id(container.name));
			
			// add entity to group
			group.addEntity( containerEntity );

			return containerEntity;
		}
	}
}