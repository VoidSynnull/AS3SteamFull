package game.creators.ui
{
	import flash.geom.Point;

	import ash.core.Entity;

	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;

	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.ui.FloatingToolTip;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.data.ui.ToolTipType;
	import game.util.EntityUtils;

	public class ToolTipCreator
	{
		/**
		 * Creates a static tooltip to display on non-moving entity's like doors, static characters or items.
		 */
		public static function create(type:String, x:Number, y:Number, label:String = null, offset:Point = null, scale:Number = 1.5):Entity
		{
			var entity:Entity = new Entity();
			var display:Display = new Display();
			var spatial:Spatial = new Spatial();
			var scaleFactor:Number = scale; // TO DO: Change size based on device. //Capabilities.screenDPI / 72
			var sleep:Sleep = new Sleep();
			sleep.useEdgeForBounds = true;

			spatial.scaleX = spatial.scaleY = scaleFactor
			spatial.x = x;
			spatial.y = y;

			if(offset != null)
			{
				spatial.x += offset.x;
				spatial.y += offset.y;
			}

			var toolTip:ToolTip = new ToolTip();
			toolTip.showing = false;
			toolTip.viewedOnce = false;
			toolTip.type = type;
			toolTip.label = label;

			entity.add(sleep);
			entity.add(display);
			entity.add(spatial);
			entity.add(toolTip);
			entity.add(new ToolTipActive());
			entity.add(new FloatingToolTip());
			entity.add(new Tween());

			return(entity);
		}

		/**
		 * Creates a tooltip that will follow an entity.
		 */
		public static function addToEntity(parent:Entity, type:String = ToolTipType.CLICK, label:String = null, offset:Point = null, addToParentGroup:Boolean = true, scale:Number = 1.5):Entity
		{
			var entity:Entity = EntityUtils.getChildById(parent, "tooltip", false);
			//check if parent already has a tooltip before adding one
			if( entity == null )
			{
				entity = new Entity();
				var display:Display = new Display();
				var spatial:Spatial = parent.get(Spatial);
				var toolTip:ToolTip = new ToolTip();
				var spatialOffset:SpatialOffset = new SpatialOffset();

				spatialOffset.scaleX = spatialOffset.scaleY += (scale - spatial.scale);

				toolTip.showing = false;
				toolTip.viewedOnce = false;
				toolTip.type = type;
				toolTip.label = label;

				entity.add(display);
				entity.add(new Spatial());
				entity.add(toolTip);
				entity.add(new FloatingToolTip());
				entity.add(new FollowTarget(spatial, 1, false));
				entity.add(new ToolTipActive());
				entity.add(new Id("tooltip"));
				entity.add(spatialOffset);
				entity.add(new Tween());

				if(offset != null)
				{
					spatialOffset.x = offset.x;
					spatialOffset.y = offset.y;
				}

				EntityUtils.addParentChild(entity, parent, addToParentGroup);
			}

			return(entity);
		}

		public static function removeFromEntity(entity:Entity):void
		{
			var children:Children = entity.get(Children);
			if(children)
			{
				for (var i:int = 0; i < children.children.length; i++)
				{
					if(children.children[i].has(ToolTip))
					{
						children.children[i].remove(ToolTip);
						children.children[i].remove(FloatingToolTip);
						children.children[i].remove(ToolTipActive);
						entity.group.removeEntity(children.children[i]);
						break;
					}
				}
			}
			else
			{
				if(entity.get(ToolTip))
				{
					entity.remove(ToolTip);
					entity.remove(ToolTipActive);
				}
			}
		}

		/**
		 * Adds a tooltip component to a ui element for the purpose of displaying a rollover.  Will NOT create a floating tooltip above the entity.
		 */
		public static function addUIRollover(entity:Entity, type:String = null, label:String = null):ToolTip
		{
			if(type == null)
			{
				type = ToolTipType.CLICK;
			}

			var toolTip:ToolTip = new ToolTip();
			toolTip.showing = false;
			toolTip.viewedOnce = false;
			toolTip.type = type;
			toolTip.label = label;

			entity.add(toolTip);
			entity.add(new ToolTipActive());

			return(toolTip);
		}
	}
}
