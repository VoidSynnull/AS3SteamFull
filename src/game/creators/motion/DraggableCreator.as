package game.creators.motion
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.motion.Draggable;
	import game.creators.ui.ToolTipCreator;
	import game.systems.motion.DraggableSystem;
	import game.util.EntityUtils;

	public class DraggableCreator
	{
		public static function create(group:Group, displayObject:DisplayObjectContainer, container:DisplayObjectContainer = null):Entity
		{
			group.addSystem(new DraggableSystem());
			
			var entity:Entity = EntityUtils.createSpatialEntity(group, displayObject, container);
			InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			entity.add(new Draggable());
			
			ToolTipCreator.addToEntity(entity);
			
			return entity;
		}
		
		
		/*public static function addToEntity( entity:Entity, group:Group = null, target:Entity = null, displayObject:DisplayObjectContainer = null, bounds:Rectangle = null, edge:Rectangle = null, rate:Number = 1, offset:Point = null, applyCameraOffset:Boolean = false, properties:Vector.<String> = null ):void
		{
			if( !displayObject )
			{
				var display:Display = entity.get(Display);
				if( display )
				{
					displayObject = display.displayObject;
				}
				else
				{
					trace( "Error :: DraggableCreator : A DisplayObject must be available." );
					return;
				}
			}
			var interactions:Array = [ InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT ];
			var interaction:Interaction = entity.get(Interaction);
			if( !interaction )
			{
				interaction = InteractionCreator.addToEntity( entity, interactions, displayObject );
			}
			else
			{
				InteractionCreator.addToComponent( displayObject, interactions, interaction );
			}
			
			var draggable:Draggable = new Draggable();
			draggable.onStartDrag = new Signal( Entity );
			draggable.onEndDrag = new Signal( Entity );
			entity.add( draggable );

			interaction.down.add( draggable.onEnable );
			interaction.up.add( draggable.onRelease );
			interaction.releaseOutside.add( draggable.onRelease );
			
			if( !target )
			{
				if( group )
				{
					target = group.shellApi.inputEntity;
				}
				else
				{
					trace( "Error :: DraggableCreator : A target must be available." );
					return;
				}
			}
			EntityUtils.followTarget( entity, target, rate, offset, applyCameraOffset, properties ); 
			
			if( bounds )
			{
				var motionBounds:MotionBounds = new MotionBounds();
				motionBounds.box = bounds; 
				entity.add( motionBounds );
				if( group ) 	{ group.addSystem( new BoundsCheckSystem() ); }
				
				if( edge )
				{
					var edgeComponent:EdgeBasic = new EdgeBasic( edge.left, edge.top, edge.right, edge.bottom );
					entity.add( edgeComponent );
				}
			}
		}*/
	}
}