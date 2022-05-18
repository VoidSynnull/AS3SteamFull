package game.adparts.creators
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.adparts.parts.AdVideo;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.ui.ToolTipType;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class AdVideoCreator
	{
		/**
		 * Constructor
		 */
		public function AdVideoCreator():void
		{
		}
		
		/**
		 * Create AdVideo entity
		 * @param	group			Scene where the video is loaded
		 * @param	container		video container movieclip
		 * @param	videoData		object with all video data
		 */
		public function create(group:Group, container:MovieClip, videoData:Object, suffix:String = ""):Entity
		{
			// convert video container movieclip to timeline entity (the new containers should have one frame only)
			if (container.totalFrames != 1)
			{
				var vTimeline:Entity = TimelineUtils.convertClip(container, group);
				vTimeline.get(Timeline).gotoAndStop(0);
			}
			
			//create entity for container
			_adVideo = new AdVideo(vTimeline, container, videoData, group);
			var containerEntity:Entity = new Entity().add(_adVideo);
			var display:Display = new Display(container);
			display.isStatic = true;
			containerEntity.add(new Spatial(container.x, container.y));
			containerEntity.add(display);
			containerEntity.add(new Id(container.name));
			
			// add entity to group
			group.addEntity( containerEntity );
			
			// if newer video
			if (vTimeline == null)
			{
				// this fixes issue with interior buttons not working
				container.mouseChildren = true;
				
				// for each child of container
				for (var i:int = container.numChildren-1; i!=-1; i--)
				{
					var clip:DisplayObject = container.getChildAt(i);
					// skip if simplebutton
					if (clip is SimpleButton)
						continue;
					clip = DisplayUtils.replaceClip(clip, suffix);
					var name:String = clip.name;
					// if clickURL or play or replay button
					if ((name.indexOf("clickURLButton") != -1) || (name.indexOf("playButton") != -1))
					{
						var buttonEntity:Entity = ButtonCreator.createButtonEntity(DisplayObjectContainer(clip), group, _adVideo.clickButton, container);
						// if clickURL or replay button, then hide
						if ((name.indexOf("clickURLButton") != -1) || (name.indexOf("replayButton") != -1))
							buttonEntity.get(Display).visible = false;
					}
					// if next button (used for sequential videos)
					else if (name == "nextButton")
					{
						buttonEntity = ButtonCreator.createButtonEntity(DisplayObjectContainer(clip), group, _adVideo.fnPlay, container);
						buttonEntity.get(Display).visible = false;
						// set sequential videos flag
						_adVideo.setSequentialVideos();
					}
					// if end screens then hide (used for sequential videos)
					// note: the last video doesn't need an end screen because we show the replay button, if available (should have one or the other)
					else if (name.indexOf("endScreen") != -1)
					{
						var entity:Entity = EntityUtils.createDisplayEntity(group, clip, container);
						entity.get(Display).visible = false;
						entity.add(new Id(name));
						clip.visible = false;
					}
					// game buttons
					else if (name.indexOf("GameButton") != -1)
					{
						buttonEntity = ButtonCreator.createButtonEntity(DisplayObjectContainer(clip), group, _adVideo.clickButton, container);
						// if second Game Button
						if (name.indexOf("secondGameButton") != -1)
							buttonEntity.get(Display).visible = false;
					}
				}
			}
			else
			{
				// add tooltip
				var offset:Point = new Point(container.width/2, container.height/2);
				ToolTipCreator.addToEntity(containerEntity, ToolTipType.CLICK, null, offset);
				
				// create interaction for clicking on video container
				var interaction:Interaction = InteractionCreator.addToEntity(containerEntity, [InteractionCreator.CLICK], container);
				interaction.click.add(fnHandleClicked);
			}
			
			return containerEntity;
		}
		
		/**
		 * Handle mouse clicks
		 * @param	clickedEntity	Video container entity clicked on
		 */
		private function fnHandleClicked(clickedEntity:Entity):void
		{
			_adVideo.fnClick();
		}
		
		private var _adVideo:AdVideo;
	}
}