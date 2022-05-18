package game.creators.scene
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.scene.DoorData;
	import game.data.scene.labels.LabelData;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.util.EntityUtils;

	public class DoorCreator
	{
		private const DEFAULT_DELTA_X:int = 30;
		private const DEFAULT_DELTA_Y:int = 100;
		
		public function create(doorDisplay:DisplayObjectContainer, doorData:DoorData, audioGroup:AudioGroup = null, group:Group = null, preConfiguredComponent:Door = null):Entity
		{
			var door:Entity = new Entity();
			var labelData:LabelData = doorData.label;
			
			var display:Display = new Display();
			display.displayObject = doorDisplay;
			display.isStatic = true;
			display.alpha = 0;
			doorDisplay.mouseEnabled = true;
			
			var spatial:Spatial = new Spatial();
			EntityUtils.syncSpatial(spatial, doorDisplay);
			
			var doorHit:Door;
			
			if(preConfiguredComponent != null)
			{
				doorHit = preConfiguredComponent;
			}
			else
			{
				doorHit = new Door();
				doorHit.data = doorData;
			}
	
			door.add(spatial);
			door.add(display);
			door.add(new Id(doorData.id));
			door.add(doorHit);
			door.add(new Sleep());
			
			if(audioGroup != null)
			{
				audioGroup.addAudioToEntity(door);
			}
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = 0;
			sceneInteraction.offsetY = 0;
			
			if(!isNaN(doorData.minDistanceX))
			{
				sceneInteraction.minTargetDelta.x = doorData.minDistanceX;
			}
			else
			{
				sceneInteraction.minTargetDelta.x = DEFAULT_DELTA_X;
			}
	
			if(!isNaN(doorData.minDistanceY))
			{
				sceneInteraction.minTargetDelta.y = doorData.minDistanceY;
			}
			else
			{
				sceneInteraction.minTargetDelta.y = DEFAULT_DELTA_Y;
			}
			
			door.add(sceneInteraction);
			
			InteractionCreator.addToEntity(door, [InteractionCreator.CLICK]);
			
			if(group != null)
			{
				group.addEntity(door);
				
				if(labelData == null)
				{
					labelData = new LabelData();
					labelData.type = ToolTipType.EXIT_3D;
				}
				
				if(labelData.offset == null)
				{
					labelData.offset = new Point();
				}
				
				var interactionBounds:Rectangle = doorDisplay.getBounds(doorDisplay.parent);
				labelData.offset.x += (interactionBounds.x - doorDisplay.x) + interactionBounds.width * .5;
				labelData.offset.y += (interactionBounds.y - doorDisplay.y) + interactionBounds.height * .5;
				
				if(labelData.id == null)
				{
					labelData.id = doorData.id;
				}
				// if not exitToMap or not mobile, then add tooltip
				if ((doorData.id.toLowerCase() != "exittomap") || (!AppConfig.mobile))
					ToolTipCreator.addToEntity(door, labelData.type, labelData.text, labelData.offset);
			}
			
			return(door);
		}
	}
}